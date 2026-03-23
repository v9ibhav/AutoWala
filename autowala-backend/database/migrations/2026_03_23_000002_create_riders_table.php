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
        Schema::create('riders', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('user_id')->unsigned()->unique();
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');

            // Profile
            $table->string('full_name', 255);
            $table->string('phone_number', 20);
            $table->string('country_code', 5)->default('+91');
            $table->text('profile_photo_url')->nullable();

            // KYC Status
            $table->enum('kyc_status', ['pending', 'verified', 'rejected', 'expired'])->default('pending');
            $table->timestamp('kyc_verified_at')->nullable();
            $table->text('kyc_rejection_reason')->nullable();

            // Vehicle Info (will be added after vehicles table is created)
            $table->bigInteger('vehicle_id')->unsigned()->nullable();

            // Ratings & Reputation
            $table->decimal('average_rating', 3, 2)->default(5.0);
            $table->integer('total_rides')->default(0);

            // Current Status
            $table->boolean('is_online')->default(false);
            $table->timestamp('last_online_at')->nullable();

            // Location (PostGIS)
            // We'll add this as a raw geometry column
            $table->timestamp('location_updated_at')->nullable();

            // Settings
            $table->string('preferred_language', 10)->default('en');
            $table->decimal('fare_per_passenger', 10, 2)->default(30.00);

            // Account
            $table->boolean('is_active')->default(true);
            $table->timestamp('account_suspended_at')->nullable();
            $table->text('suspension_reason')->nullable();

            // Timestamps
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();

            // Indexes
            $table->index(['user_id', 'deleted_at'], 'idx_riders_user_active');
            $table->index('is_online');
            $table->index('kyc_status');
            $table->index(['is_active', 'is_online']);
            $table->index('location_updated_at');
        });

        // Add PostGIS location column
        DB::statement('ALTER TABLE riders ADD COLUMN current_location GEOMETRY(POINT, 4326)');

        // Create spatial index for location
        DB::statement('CREATE INDEX idx_riders_location_spatial ON riders USING GIST(current_location)');

        // Create composite index for online riders with recent location
        DB::statement('
            CREATE INDEX idx_riders_online_location
            ON riders(is_online, location_updated_at)
            WHERE is_online = TRUE AND current_location IS NOT NULL
        ');

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_riders_updated_at
            BEFORE UPDATE ON riders
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
        DB::statement('DROP TRIGGER IF EXISTS update_riders_updated_at ON riders');

        // Drop spatial indexes
        DB::statement('DROP INDEX IF EXISTS idx_riders_location_spatial');
        DB::statement('DROP INDEX IF EXISTS idx_riders_online_location');

        Schema::dropIfExists('riders');
    }
};