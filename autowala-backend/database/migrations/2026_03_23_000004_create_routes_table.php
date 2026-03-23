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
        Schema::create('routes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('rider_id')->unsigned();
            $table->foreign('rider_id')->references('id')->on('riders')->onDelete('cascade');

            // Route Details
            $table->string('route_name', 255)->nullable(); // e.g., "Andheri - Fort"
            $table->text('description')->nullable();

            // Status
            $table->boolean('is_active')->default(true);

            // Statistics
            $table->decimal('total_distance_km', 8, 2)->nullable();
            $table->integer('estimated_duration_min')->nullable();

            // Timestamps
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();

            // Indexes
            $table->index('rider_id');
            $table->index(['is_active', 'deleted_at']);
            $table->index(['rider_id', 'is_active']);
        });

        // Add PostGIS route geometry column
        DB::statement('ALTER TABLE routes ADD COLUMN route_geometry GEOMETRY(LINESTRING, 4326)');

        // Create spatial index for route geometry
        DB::statement('CREATE INDEX idx_routes_geometry_spatial ON routes USING GIST(route_geometry)');

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_routes_updated_at
            BEFORE UPDATE ON routes
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
        DB::statement('DROP TRIGGER IF EXISTS update_routes_updated_at ON routes');

        // Drop spatial index
        DB::statement('DROP INDEX IF EXISTS idx_routes_geometry_spatial');

        Schema::dropIfExists('routes');
    }
};