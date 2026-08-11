<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Workspace;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'workspace_name' => ['required', 'string', 'max:120'],
        ]);

        [$user, $workspace] = DB::transaction(function () use ($data) {
            $user = User::create($data);
            $workspace = Workspace::create([
                'name' => $data['workspace_name'],
                'slug' => Str::slug($data['workspace_name']) . '-' . Str::lower(Str::random(5)),
            ]);
            $workspace->users()->attach($user->id, ['role' => 'owner']);
            return [$user, $workspace];
        });

        return response()->json(['user' => $user, 'workspace' => $workspace, 'token' => $user->createToken('omnichannel-mobile')->plainTextToken], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email'], 'password' => ['required', 'string']]);
        $user = User::where('email', $data['email'])->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => ['Invalid credentials.']]);
        }
        $user->tokens()->delete();
        return response()->json(['user' => $user, 'workspaces' => $user->workspaces, 'token' => $user->createToken('omnichannel-mobile')->plainTextToken]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();
        return response()->json(['message' => 'Logged out successfully.']);
    }
}
