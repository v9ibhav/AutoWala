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
        Schema::create('notifications', function (Blueprint $table) {
            $table->bigIncrements('id');

            // Recipient (either user or rider, not both)
            $table->bigInteger('user_id')->unsigned()->nullable();
            $table->bigInteger('rider_id')->unsigned()->nullable();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('rider_id')->references('id')->on('riders')->onDelete('cascade');

            // Content
            $table->enum('notification_type', [
                'auto_nearby',
                'ride_started',
                'eta_update',
                'rider_arrived',
                'ride_completed',
                'ride_cancelled',
                'rating_request',
                'kyc_approved',
                'kyc_rejected',
                'account_suspended'
            ]);
            $table->string('title', 255);
            $table->text('message');

            // Metadata
            $table->bigInteger('related_ride_log_id')->unsigned()->nullable();
            $table->foreign('related_ride_log_id')->references('id')->on('ride_logs')->onDelete('cascade');
            $table->json('data')->nullable(); // Additional JSON data

            // Status
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();

            // FCM
            $table->string('fcm_message_id', 255)->nullable();

            // Timestamps
            $table->timestamps();

            // Indexes
            $table->index('user_id');
            $table->index('rider_id');
            $table->index('notification_type');
            $table->index('is_read');
            $table->index(['user_id', 'is_read']);
            $table->index(['rider_id', 'is_read']);
            $table->index('created_at');
            $table->index('related_ride_log_id');
        });

        // Add constraint: either user_id or rider_id must be set, but not both
        DB::statement('
            ALTER TABLE notifications ADD CONSTRAINT chk_notifications_recipient
            CHECK (
                (user_id IS NOT NULL AND rider_id IS NULL) OR
                (user_id IS NULL AND rider_id IS NOT NULL)
            )
        ');

        // Create index for recent unread notifications
        DB::statement("
            CREATE INDEX idx_notifications_recent_unread
            ON notifications(created_at)
            WHERE is_read = false AND created_at >= NOW() - INTERVAL '7 days'
        ");

        // No auto-update trigger needed for read-only timestamp table
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop custom indexes
        DB::statement('DROP INDEX IF EXISTS idx_notifications_recent_unread');

        Schema::dropIfExists('notifications');
    }
};