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
        Schema::create('route_points', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('route_id')->unsigned();
            $table->foreign('route_id')->references('id')->on('routes')->onDelete('cascade');

            // Location Details
            $table->string('location_name', 255)->nullable(); // e.g., "Andheri Station"
            $table->text('location_address')->nullable();
            $table->decimal('location_lat', 10, 8);
            $table->decimal('location_lon', 11, 8);

            // Sequence
            $table->integer('sequence_order');

            // Timing
            $table->integer('estimated_arrival_min')->nullable(); // Minutes from route start

            // Timestamps
            $table->timestamps();

            // Indexes
            $table->index('route_id');
            $table->index(['route_id', 'sequence_order']);
            $table->index(['location_lat', 'location_lon']);
        });

        // Add PostGIS point geometry column
        DB::statement('ALTER TABLE route_points ADD COLUMN location_geom GEOMETRY(POINT, 4326)');

        // Create spatial index for location geometry
        DB::statement('CREATE INDEX idx_route_points_geom_spatial ON route_points USING GIST(location_geom)');

        // Create trigger to automatically update geometry when lat/lon changes
        DB::statement('
            CREATE OR REPLACE FUNCTION update_route_point_geometry()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.location_geom = ST_GeomFromText(\'POINT(\' || NEW.location_lon || \' \' || NEW.location_lat || \')\', 4326);
                RETURN NEW;
            END;
            $$ language \'plpgsql\'
        ');

        // Apply geometry update trigger
        DB::statement('
            CREATE TRIGGER update_route_points_geometry
            BEFORE INSERT OR UPDATE ON route_points
            FOR EACH ROW
            EXECUTE FUNCTION update_route_point_geometry()
        ');

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_route_points_updated_at
            BEFORE UPDATE ON route_points
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column()
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop triggers
        DB::statement('DROP TRIGGER IF EXISTS update_route_points_geometry ON route_points');
        DB::statement('DROP TRIGGER IF EXISTS update_route_points_updated_at ON route_points');

        // Drop spatial index
        DB::statement('DROP INDEX IF EXISTS idx_route_points_geom_spatial');

        // Drop geometry update function
        DB::statement('DROP FUNCTION IF EXISTS update_route_point_geometry()');

        Schema::dropIfExists('route_points');
    }
};