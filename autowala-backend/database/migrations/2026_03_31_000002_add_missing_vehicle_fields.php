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
        Schema::table('vehicles', function (Blueprint $table) {
            // Add insurance details
            $table->string('insurance_number', 50)->nullable()->after('insurance_doc_url');
            $table->date('insurance_expiry')->nullable()->after('insurance_number');

            // Add verification status as string (controllers expect this instead of boolean is_verified)
            $table->enum('verification_status', ['pending', 'approved', 'rejected', 'expired'])
                  ->default('pending')
                  ->after('is_verified');

            // Add capacity alias (controllers expect 'capacity' field name)
            // Note: We'll handle this via accessor in model, not adding duplicate field

            // Index for performance
            $table->index('verification_status');
            $table->index('insurance_expiry');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropIndex(['verification_status']);
            $table->dropIndex(['insurance_expiry']);

            $table->dropColumn([
                'insurance_number',
                'insurance_expiry',
                'verification_status',
            ]);
        });
    }
};