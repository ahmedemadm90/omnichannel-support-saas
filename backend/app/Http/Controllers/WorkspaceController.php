<?php

namespace App\Http\Controllers;

use App\Models\Workspace;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkspaceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->workspaces()->withCount(['contacts', 'conversations'])->get()]);
    }

    public function show(Request $request, Workspace $workspace): JsonResponse
    {
        $this->ensureMember($request, $workspace);
        return response()->json($workspace->loadCount(['contacts', 'conversations'])->load('users:id,name,email'));
    }

    private function ensureMember(Request $request, Workspace $workspace): void
    {
        abort_unless($request->user()->workspaces()->whereKey($workspace->id)->exists(), 403, 'Workspace access denied.');
    }
}
