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
        Schema::create('vehicles', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('rider_id')->unsigned();
            $table->foreign('rider_id')->references('id')->on('riders')->onDelete('cascade');

            // Vehicle Details
            $table->string('registration_number', 20)->unique();
            $table->string('make', 100)->nullable(); // 'Bajaj', 'Piaggio', etc.
            $table->string('model', 100)->nullable();
            $table->string('color', 50)->nullable();
            $table->integer('year')->nullable();

            // Capacity
            $table->integer('max_passengers')->default(3);

            // Documents
            $table->text('registration_doc_url')->nullable();
            $table->text('insurance_doc_url')->nullable();
            $table->text('pollution_certificate_url')->nullable();

            // Status
            $table->boolean('is_verified')->default(false);
            $table->text('verification_notes')->nullable();

            // Timestamps
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();

            // Indexes
            $table->index('rider_id');
            $table->index(['is_verified', 'deleted_at']);
        });

        // Create unique index for active vehicles only
        DB::statement('
            CREATE UNIQUE INDEX idx_vehicles_registration_unique
            ON vehicles(registration_number)
            WHERE deleted_at IS NULL
        ');

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_vehicles_updated_at
            BEFORE UPDATE ON vehicles
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column()
        ');

        // Now add the foreign key to riders table
        Schema::table('riders', function (Blueprint $table) {
            $table->foreign('vehicle_id')->references('id')->on('vehicles')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Remove foreign key from riders table first
        Schema::table('riders', function (Blueprint $table) {
            $table->dropForeign(['vehicle_id']);
        });

        // Drop trigger
        DB::statement('DROP TRIGGER IF EXISTS update_vehicles_updated_at ON vehicles');

        // Drop the table
        Schema::dropIfExists('vehicles');
    }
};