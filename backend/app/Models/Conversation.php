<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = ['workspace_id', 'contact_id', 'assigned_to', 'channel', 'status', 'priority', 'subject', 'last_message_at'];
    protected $casts = ['last_message_at' => 'datetime'];

    public function workspace(): BelongsTo { return $this->belongsTo(Workspace::class); }
    public function contact(): BelongsTo { return $this->belongsTo(Contact::class); }
    public function assignee(): BelongsTo { return $this->belongsTo(User::class, 'assigned_to'); }
    public function messages(): HasMany { return $this->hasMany(Message::class); }
}
