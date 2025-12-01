<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label(__('users.name.label'))
                    ->placeholder(__('users.name.placeholder'))
                    ->required(),
                TextInput::make('email')
                    ->label(__('users.email.label'))
                    ->placeholder(__('users.email.placeholder'))
                    ->email()
                    ->required(),
                DateTimePicker::make('email_verified_at')
                    ->label(__('users.email_verified_at.label'))
                    ->placeholder(__('users.email_verified_at.placeholder')),
                TextInput::make('password')
                    ->label(__('users.password.label'))
                    ->placeholder(__('users.password.placeholder'))
                    ->password()
                    ->required(),
            ]);
    }
}
