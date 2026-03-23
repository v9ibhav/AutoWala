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
        Schema::create('ride_logs', function (Blueprint $table) {
            $table->bigIncrements('id');

            // Parties
            $table->bigInteger('user_id')->unsigned();
            $table->bigInteger('rider_id')->unsigned();
            $table->bigInteger('vehicle_id')->unsigned();
            $table->bigInteger('route_id')->unsigned()->nullable();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('rider_id')->references('id')->on('riders')->onDelete('cascade');
            $table->foreign('vehicle_id')->references('id')->on('vehicles')->onDelete('cascade');
            $table->foreign('route_id')->references('id')->on('routes')->onDelete('set null');

            // Pickup & Dropoff Information
            $table->string('pickup_location_name', 255)->nullable();
            $table->decimal('pickup_lat', 10, 8)->nullable();
            $table->decimal('pickup_lon', 11, 8)->nullable();
            $table->text('pickup_address')->nullable();

            $table->string('dropoff_location_name', 255)->nullable();
            $table->decimal('dropoff_lat', 10, 8)->nullable();
            $table->decimal('dropoff_lon', 11, 8)->nullable();
            $table->text('dropoff_address')->nullable();

            // Ride Details
            $table->enum('status', ['matched', 'in_transit', 'completed', 'cancelled'])->default('matched');
            $table->integer('no_of_passengers')->default(1);

            // Fare (Display only - payment is CASH)
            $table->decimal('fare_amount', 10, 2)->nullable();
            $table->string('fare_currency', 3)->default('INR');

            // Tracking
            $table->integer('pickup_route_index')->nullable(); // Which stop point in the route
            $table->boolean('is_user_picked_up')->default(false);
            $table->boolean('is_ride_completed')->default(false);

            // Navigation & Timing
            $table->timestamp('estimated_pickup_time')->nullable();
            $table->timestamp('estimated_dropoff_time')->nullable();
            $table->timestamp('actual_pickup_time')->nullable();
            $table->timestamp('actual_dropoff_time')->nullable();

            // Distance & Time
            $table->decimal('actual_distance_km', 8, 2)->nullable();
            $table->integer('actual_duration_min')->nullable();

            // Firebase Session ID (for real-time tracking)
            $table->string('firebase_session_id', 255)->unique()->nullable();

            // Cancellation
            $table->enum('cancelled_by', ['user', 'rider', 'system'])->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancellation_reason')->nullable();

            // Timestamps
            $table->timestamps();
            $table->timestamp('completed_at')->nullable();

            // Indexes
            $table->index('user_id');
            $table->index('rider_id');
            $table->index('vehicle_id');
            $table->index('route_id');
            $table->index('status');
            $table->index('created_at');
            $table->index('firebase_session_id');
            $table->index(['user_id', 'status']);
            $table->index(['rider_id', 'status']);
            $table->index(['status', 'created_at']);
        });

        // Add indexes for location-based queries
        DB::statement('CREATE INDEX idx_ride_logs_pickup_location ON ride_logs(pickup_lat, pickup_lon)');
        DB::statement('CREATE INDEX idx_ride_logs_dropoff_location ON ride_logs(dropoff_lat, dropoff_lon)');

        // Create index for active rides
        DB::statement("
            CREATE INDEX idx_ride_logs_active
            ON ride_logs(status, created_at)
            WHERE status IN ('matched', 'in_transit')
        ");

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_ride_logs_updated_at
            BEFORE UPDATE ON ride_logs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column()
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop trigger
        DB::statement('DROP TRIGGER IF EXISTS update_ride_logs_updated_at ON ride_logs');

        // Drop custom indexes
        DB::statement('DROP INDEX IF EXISTS idx_ride_logs_pickup_location');
        DB::statement('DROP INDEX IF EXISTS idx_ride_logs_dropoff_location');
        DB::statement('DROP INDEX IF EXISTS idx_ride_logs_active');

        Schema::dropIfExists('ride_logs');
    }
};