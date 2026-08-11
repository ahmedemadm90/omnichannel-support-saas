<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OmniMessageCreated implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public Message $message)
    {
        $this->message->loadMissing('conversation:id,workspace_id,contact_id,channel,status', 'conversation.contact:id,name,email,phone', 'sender:id,name');
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('workspace.' . $this->message->conversation->workspace_id)];
    }

    public function broadcastAs(): string
    {
        return 'inbox.message.created';
    }

    public function broadcastWith(): array
    {
        return ['message' => $this->message];
    }
}
