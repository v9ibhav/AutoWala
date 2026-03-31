<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rides', function (Blueprint $table) {
            $table->id();

            // Relationships
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('rider_id')->nullable()->constrained()->onDelete('set null');

            // Location data (stored as JSON for flexibility)
            $table->json('pickup_location'); // {latitude: float, longitude: float}
            $table->json('dropoff_location'); // {latitude: float, longitude: float}
            $table->string('pickup_address');
            $table->string('dropoff_address');

            // Timing
            $table->timestamp('pickup_time')->nullable();
            $table->timestamp('dropoff_time')->nullable();
            $table->timestamp('scheduled_at')->nullable(); // For future scheduled rides

            // Ride details
            $table->enum('status', ['pending', 'matched', 'in_transit', 'completed', 'cancelled'])
                  ->default('pending')
                  ->index();
            $table->tinyInteger('passenger_count')->default(1);
            $table->decimal('fare', 8, 2)->nullable(); // Calculated or estimated fare
            $table->decimal('distance_km', 8, 2)->nullable(); // Calculated distance
            $table->integer('duration_minutes')->nullable(); // Actual ride duration

            // Additional info
            $table->text('notes')->nullable(); // Special instructions or cancellation reasons

            // Indexes for performance
            $table->index(['user_id', 'status']);
            $table->index(['rider_id', 'status']);
            $table->index('created_at');

            $table->timestamps();
            $table->softDeletes(); // For data retention and analytics
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rides');
    }
};