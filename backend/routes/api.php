<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\InboxController;
use App\Http\Controllers\WorkspaceController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('workspaces/{workspace}/webhooks/inbound', [InboxController::class, 'ingestWebhook']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('workspaces', [WorkspaceController::class, 'index']);
        Route::get('workspaces/{workspace}', [WorkspaceController::class, 'show']);
        Route::get('workspaces/{workspace}/conversations', [InboxController::class, 'index']);
        Route::get('workspaces/{workspace}/conversations/{conversation}', [InboxController::class, 'show']);
        Route::post('workspaces/{workspace}/conversations/{conversation}/messages', [InboxController::class, 'send']);
        Route::patch('workspaces/{workspace}/conversations/{conversation}', [InboxController::class, 'updateStatus']);
    });
});
