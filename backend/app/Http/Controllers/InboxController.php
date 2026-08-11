<?php

namespace App\Http\Controllers;

use App\Events\OmniMessageCreated;
use App\Models\Contact;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InboxController extends Controller
{
    public function index(Request $request, int $workspaceId): JsonResponse
    {
        $this->ensureMember($request, $workspaceId);
        $conversations = Conversation::query()
            ->where('workspace_id', $workspaceId)
            ->with(['contact:id,name,email,phone,avatar_url', 'assignee:id,name', 'messages' => fn ($query) => $query->latest()->limit(1)])
            ->when($request->string('status')->trim()->value(), fn ($query, string $status) => $query->where('status', $status))
            ->when($request->string('channel')->trim()->value(), fn ($query, string $channel) => $query->where('channel', $channel))
            ->latest('last_message_at')
            ->paginate(min($request->integer('per_page', 30), 100));

        return response()->json($conversations);
    }

    public function show(Request $request, int $workspaceId, Conversation $conversation): JsonResponse
    {
        $this->ensureConversation($request, $workspaceId, $conversation);
        return response()->json($conversation->load(['contact', 'assignee:id,name', 'messages' => fn ($query) => $query->with('sender:id,name')->oldest()]));
    }

    public function send(Request $request, int $workspaceId, Conversation $conversation): JsonResponse
    {
        $this->ensureConversation($request, $workspaceId, $conversation);
        $data = $request->validate(['body' => ['required', 'string', 'max:5000'], 'message_type' => ['nullable', 'in:text,note']]);
        $message = DB::transaction(function () use ($request, $conversation, $data) {
            $message = $conversation->messages()->create([
                'sender_id' => $request->user()->id,
                'sender_type' => 'agent',
                'body' => trim($data['body']),
                'message_type' => $data['message_type'] ?? 'text',
            ]);
            $conversation->update(['last_message_at' => now(), 'assigned_to' => $request->user()->id]);
            return $message->load('sender:id,name');
        });
        broadcast(new OmniMessageCreated($message));
        return response()->json($message, 201);
    }

    public function updateStatus(Request $request, int $workspaceId, Conversation $conversation): JsonResponse
    {
        $this->ensureConversation($request, $workspaceId, $conversation);
        $data = $request->validate(['status' => ['required', 'in:open,pending,resolved'], 'priority' => ['nullable', 'in:low,normal,high,urgent']]);
        $conversation->update($data);
        return response()->json($conversation->fresh());
    }

    public function ingestWebhook(Request $request, int $workspaceId): JsonResponse
    {
        abort_unless(hash_equals((string) config('services.omnichannel.webhook_secret'), (string) $request->header('X-Omni-Secret')), 401, 'Invalid webhook signature.');
        $data = $request->validate([
            'channel' => ['required', 'in:whatsapp,telegram,email,web'],
            'contact' => ['required', 'array'],
            'contact.name' => ['required', 'string', 'max:120'],
            'contact.email' => ['nullable', 'email'],
            'contact.phone' => ['nullable', 'string', 'max:40'],
            'body' => ['required', 'string', 'max:5000'],
        ]);
        $this->ensureWorkspace($workspaceId);

        $message = DB::transaction(function () use ($workspaceId, $data) {
            $contact = Contact::firstOrCreate(
                ['workspace_id' => $workspaceId, 'email' => $data['contact']['email'] ?? null],
                ['name' => $data['contact']['name'], 'phone' => $data['contact']['phone'] ?? null]
            );
            $conversation = Conversation::firstOrCreate(
                ['workspace_id' => $workspaceId, 'contact_id' => $contact->id, 'status' => 'open'],
                ['channel' => $data['channel'], 'last_message_at' => now()]
            );
            $message = $conversation->messages()->create(['sender_type' => 'contact', 'body' => $data['body']]);
            $conversation->update(['last_message_at' => now(), 'channel' => $data['channel']]);
            return $message->load('conversation.contact');
        });
        broadcast(new OmniMessageCreated($message));
        return response()->json($message, 201);
    }

    private function ensureMember(Request $request, int $workspaceId): void
    {
        abort_unless($request->user()->workspaces()->whereKey($workspaceId)->exists(), 403, 'Workspace access denied.');
    }

    private function ensureWorkspace(int $workspaceId): void
    {
        abort_unless(\App\Models\Workspace::whereKey($workspaceId)->exists(), 404, 'Workspace not found.');
    }

    private function ensureConversation(Request $request, int $workspaceId, Conversation $conversation): void
    {
        $this->ensureMember($request, $workspaceId);
        abort_unless($conversation->workspace_id === $workspaceId, 404, 'Conversation not found.');
    }
}
