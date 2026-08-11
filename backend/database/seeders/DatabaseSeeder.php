<?php

namespace Database\Seeders;

use App\Models\Contact;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Models\Workspace;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $owner = User::updateOrCreate(
            ['email' => 'owner@omnichannel.test'],
            ['name' => 'Mariam Support', 'password' => Hash::make('password')]
        );
        $agent = User::updateOrCreate(
            ['email' => 'agent@omnichannel.test'],
            ['name' => 'Omar Agent', 'password' => Hash::make('password')]
        );
        $workspace = Workspace::updateOrCreate(
            ['slug' => 'acme-support'],
            ['name' => 'Acme Support Desk', 'plan' => 'growth', 'monthly_message_limit' => 10000]
        );
        $workspace->users()->syncWithoutDetaching([$owner->id => ['role' => 'owner'], $agent->id => ['role' => 'agent']]);

        foreach ([
            ['name' => 'Nour Ali', 'email' => 'nour@example.com', 'phone' => '+201000000001'],
            ['name' => 'Khaled Samir', 'email' => 'khaled@example.com', 'phone' => '+201000000002'],
            ['name' => 'Laila Hassan', 'email' => 'laila@example.com', 'phone' => '+201000000003'],
        ] as $contactData) {
            $contact = Contact::updateOrCreate(['workspace_id' => $workspace->id, 'email' => $contactData['email']], $contactData);
            $conversation = Conversation::firstOrCreate(
                ['workspace_id' => $workspace->id, 'contact_id' => $contact->id],
                ['channel' => collect(['whatsapp', 'telegram', 'email'])->random(), 'status' => 'open', 'priority' => collect(['normal', 'high'])->random(), 'assigned_to' => $agent->id, 'last_message_at' => now()]
            );
            if ($conversation->messages()->doesntExist()) {
                Message::create(['conversation_id' => $conversation->id, 'sender_type' => 'contact', 'body' => 'Hi, I need help with my latest order.']);
                Message::create(['conversation_id' => $conversation->id, 'sender_id' => $agent->id, 'sender_type' => 'agent', 'body' => 'Hello! I am checking that for you now.']);
            }
        }
    }
}
