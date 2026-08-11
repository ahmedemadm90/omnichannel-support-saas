<?php

use App\Models\User;
use App\Models\Workspace;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('workspace.{workspace}', function (User $user, Workspace $workspace) {
    return $workspace->users()->whereKey($user->id)->exists();
});
