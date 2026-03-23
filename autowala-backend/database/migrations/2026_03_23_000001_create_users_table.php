<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Enable PostGIS extension first
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis');
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis_topology');

        Schema::create('users', function (Blueprint $table) {
            $table->bigIncrements('id');

            // Contact Information
            $table->string('phone_number', 20)->unique();
            $table->string('country_code', 5)->default('+91');
            $table->string('full_name', 255)->nullable();

            // Profile
            $table->text('profile_photo_url')->nullable();
            $table->string('email', 255)->unique()->nullable();

            // OTP & Authentication
            $table->string('otp_code', 6)->nullable();
            $table->timestamp('otp_expires_at')->nullable();
            $table->integer('otp_attempts')->default(0);

            // Account Status
            $table->boolean('is_active')->default(true);
            $table->boolean('is_verified')->default(false);
            $table->timestamp('verified_at')->nullable();

            // Preferences
            $table->string('preferred_language', 10)->default('en');
            $table->boolean('notification_enabled')->default(true);

            // Timestamps
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();

            // Indexes
            $table->index(['phone_number', 'deleted_at'], 'idx_users_phone_active');
            $table->index('is_active');
            $table->index('created_at');
            $table->index('verified_at');
        });

        // Create unique index for active users only
        DB::statement('CREATE UNIQUE INDEX idx_users_phone_unique ON users(phone_number) WHERE deleted_at IS NULL');

        // Create auto-update timestamp trigger function
        DB::statement('
            CREATE OR REPLACE FUNCTION update_updated_at_column()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ language \'plpgsql\'
        ');

        // Apply trigger to users table
        DB::statement('
            CREATE TRIGGER update_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column()
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop trigger first
        DB::statement('DROP TRIGGER IF EXISTS update_users_updated_at ON users');

        Schema::dropIfExists('users');

        // Drop trigger function if no other tables are using it
        DB::statement('DROP FUNCTION IF EXISTS update_updated_at_column()');
    }
};