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
        Schema::create('user_ratings', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('from_user_id')->unsigned();
            $table->bigInteger('to_rider_id')->unsigned();
            $table->bigInteger('ride_log_id')->unsigned();

            $table->foreign('from_user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('to_rider_id')->references('id')->on('riders')->onDelete('cascade');
            $table->foreign('ride_log_id')->references('id')->on('ride_logs')->onDelete('cascade');

            // Rating
            $table->integer('rating')->check('rating >= 1 AND rating <= 5');
            $table->text('feedback')->nullable();

            // Timestamps
            $table->timestamps();

            // Indexes
            $table->index('from_user_id');
            $table->index('to_rider_id');
            $table->index('ride_log_id');
            $table->index(['to_rider_id', 'rating']);
        });

        // Create unique constraint - one rating per user per ride
        DB::statement('
            CREATE UNIQUE INDEX idx_unique_rating_per_ride
            ON user_ratings(from_user_id, ride_log_id)
        ');

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_user_ratings_updated_at
            BEFORE UPDATE ON user_ratings
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
        DB::statement('DROP TRIGGER IF EXISTS update_user_ratings_updated_at ON user_ratings');

        // Drop unique index
        DB::statement('DROP INDEX IF EXISTS idx_unique_rating_per_ride');

        Schema::dropIfExists('user_ratings');
    }
};