<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Contact extends Model
{
    use HasFactory;

    protected $fillable = ['workspace_id', 'name', 'email', 'phone', 'avatar_url', 'metadata'];
    protected $casts = ['metadata' => 'array'];

    public function workspace(): BelongsTo { return $this->belongsTo(Workspace::class); }
    public function conversations(): HasMany { return $this->hasMany(Conversation::class); }
}
