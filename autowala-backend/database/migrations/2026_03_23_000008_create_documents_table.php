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
        Schema::create('documents', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->bigInteger('rider_id')->unsigned();
            $table->foreign('rider_id')->references('id')->on('riders')->onDelete('cascade');

            // Document Details
            $table->enum('document_type', ['aadhar', 'license', 'registration', 'insurance', 'bank_account']);
            $table->string('document_number', 100);

            // Storage (S3 URLs)
            $table->text('document_url_front')->nullable();
            $table->text('document_url_back')->nullable();
            $table->text('document_url_additional')->nullable();

            // Verification
            $table->boolean('is_verified')->default(false);
            $table->bigInteger('verified_by_admin_id')->unsigned()->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->text('verification_notes')->nullable();

            // Expiry
            $table->date('expiry_date')->nullable();

            // Timestamps
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();

            // Indexes
            $table->index('rider_id');
            $table->index('document_type');
            $table->index(['rider_id', 'document_type']);
            $table->index(['is_verified', 'document_type']);
            $table->index('expiry_date');
        });

        // We'll add the admin foreign key after creating admins table
        // For now, just create the column structure

        // Apply auto-update timestamp trigger
        DB::statement('
            CREATE TRIGGER update_documents_updated_at
            BEFORE UPDATE ON documents
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
        DB::statement('DROP TRIGGER IF EXISTS update_documents_updated_at ON documents');

        Schema::dropIfExists('documents');
    }
};