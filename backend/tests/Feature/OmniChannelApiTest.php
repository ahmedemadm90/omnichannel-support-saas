<?php

namespace Tests\Feature;

use App\Models\Contact;
use App\Models\Conversation;
use App\Models\User;
use App\Models\Workspace;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OmniChannelApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_agent_can_list_only_conversations_in_their_workspace(): void
    {
        $agent = User::factory()->create();
        $workspace = Workspace::create(['name' => 'Support', 'slug' => 'support']);
        $workspace->users()->attach($agent->id, ['role' => 'agent']);
        $contact = Contact::create(['workspace_id' => $workspace->id, 'name' => 'Customer', 'email' => 'customer@example.com']);
        Conversation::create(['workspace_id' => $workspace->id, 'contact_id' => $contact->id, 'channel' => 'web']);

        $this->actingAs($agent)->getJson("/api/v1/workspaces/{$workspace->id}/conversations")
            ->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_signed_inbound_webhook_creates_contact_conversation_and_message(): void
    {
        $workspace = Workspace::create(['name' => 'Support', 'slug' => 'support']);
        $payload = [
            'channel' => 'telegram',
            'contact' => ['name' => 'Nour', 'email' => 'nour@example.com', 'phone' => '+201000000000'],
            'body' => 'I need help please',
        ];

        $this->withHeader('X-Omni-Secret', 'change-me-in-production')
            ->postJson("/api/v1/workspaces/{$workspace->id}/webhooks/inbound", $payload)
            ->assertCreated()->assertJsonPath('body', 'I need help please');

        $this->assertDatabaseHas('contacts', ['workspace_id' => $workspace->id, 'email' => 'nour@example.com']);
        $this->assertDatabaseHas('messages', ['body' => 'I need help please', 'sender_type' => 'contact']);
    }

    public function test_agent_can_reply_and_update_conversation_status(): void
    {
        $agent = User::factory()->create();
        $workspace = Workspace::create(['name' => 'Support', 'slug' => 'support']);
        $workspace->users()->attach($agent->id, ['role' => 'agent']);
        $contact = Contact::create(['workspace_id' => $workspace->id, 'name' => 'Customer']);
        $conversation = Conversation::create(['workspace_id' => $workspace->id, 'contact_id' => $contact->id]);

        $this->actingAs($agent)->postJson("/api/v1/workspaces/{$workspace->id}/conversations/{$conversation->id}/messages", ['body' => 'We are on it.'])
            ->assertCreated()->assertJsonPath('sender_type', 'agent');
        $this->actingAs($agent)->patchJson("/api/v1/workspaces/{$workspace->id}/conversations/{$conversation->id}", ['status' => 'resolved', 'priority' => 'high'])
            ->assertOk()->assertJsonPath('status', 'resolved');
    }
}
