"""
Tests for PHI field-level encryption

Tests HIPAA-compliant AES-256-GCM encryption for protected health information.
"""

import pytest
from app.utils.encryption import FieldEncryption
import base64


class TestFieldEncryption:
    """Test PHI encryption and decryption"""

    @pytest.fixture
    def encryption_service(self):
        """Create encryption service with test key"""
        # Generate a test 256-bit key (32 bytes)
        test_key = base64.b64encode(b"0" * 32).decode("utf-8")
        return FieldEncryption(test_key)

    def test_encrypt_decrypt_basic(self, encryption_service):
        """Test basic encryption and decryption"""
        plaintext = "sensitive medical information"

        # Encrypt
        ciphertext = encryption_service.encrypt(plaintext)

        # Verify it's encrypted (not same as plaintext)
        assert ciphertext != plaintext
        assert len(ciphertext) > len(plaintext)

        # Decrypt
        decrypted = encryption_service.decrypt(ciphertext)
        assert decrypted == plaintext

    def test_encrypt_with_associated_data(self, encryption_service):
        """Test encryption with associated data (AEAD)"""
        plaintext = "blood test results: cholesterol 200mg/dL"
        associated_data = "user_id:12345"

        # Encrypt with associated data
        ciphertext = encryption_service.encrypt(plaintext, associated_data)

        # Decrypt with same associated data - should succeed
        decrypted = encryption_service.decrypt(ciphertext, associated_data)
        assert decrypted == plaintext

        # Decrypt with different associated data - should fail
        with pytest.raises(Exception):
            encryption_service.decrypt(ciphertext, "user_id:99999")

    def test_different_plaintexts_different_ciphertexts(self, encryption_service):
        """Test that different plaintexts produce different ciphertexts"""
        plaintext1 = "diagnosis: type 2 diabetes"
        plaintext2 = "diagnosis: hypertension"

        ciphertext1 = encryption_service.encrypt(plaintext1)
        ciphertext2 = encryption_service.encrypt(plaintext2)

        assert ciphertext1 != ciphertext2

    def test_same_plaintext_different_ciphertexts(self, encryption_service):
        """Test that same plaintext produces different ciphertexts (due to nonce)"""
        plaintext = "prescription: metformin 500mg"

        ciphertext1 = encryption_service.encrypt(plaintext)
        ciphertext2 = encryption_service.encrypt(plaintext)

        # Should be different due to random nonce
        assert ciphertext1 != ciphertext2

        # But both should decrypt to same plaintext
        assert encryption_service.decrypt(ciphertext1) == plaintext
        assert encryption_service.decrypt(ciphertext2) == plaintext

    def test_encrypt_empty_string(self, encryption_service):
        """Test encryption of empty string"""
        plaintext = ""

        ciphertext = encryption_service.encrypt(plaintext)
        decrypted = encryption_service.decrypt(ciphertext)

        assert decrypted == plaintext

    def test_encrypt_unicode_text(self, encryption_service):
        """Test encryption of unicode text"""
        plaintext = "患者症状：高血压 (Patient symptoms: hypertension)"

        ciphertext = encryption_service.encrypt(plaintext)
        decrypted = encryption_service.decrypt(ciphertext)

        assert decrypted == plaintext

    def test_decrypt_invalid_ciphertext(self, encryption_service):
        """Test that decrypting invalid ciphertext raises exception"""
        invalid_ciphertext = "not_valid_base64!"

        with pytest.raises(Exception):
            encryption_service.decrypt(invalid_ciphertext)

    def test_decrypt_corrupted_ciphertext(self, encryption_service):
        """Test that decrypting corrupted ciphertext raises exception"""
        plaintext = "medical record data"
        ciphertext = encryption_service.encrypt(plaintext)

        # Corrupt the ciphertext
        decoded = base64.b64decode(ciphertext)
        corrupted = decoded[:-5] + b"XXXXX"
        corrupted_b64 = base64.b64encode(corrupted).decode("utf-8")

        with pytest.raises(Exception):
            encryption_service.decrypt(corrupted_b64)

    def test_long_plaintext(self, encryption_service):
        """Test encryption of long plaintext"""
        plaintext = "Medical history: " + "Patient has a long medical history. " * 100

        ciphertext = encryption_service.encrypt(plaintext)
        decrypted = encryption_service.decrypt(ciphertext)

        assert decrypted == plaintext

    def test_special_characters(self, encryption_service):
        """Test encryption of special characters and newlines"""
        plaintext = "Lab results:\n- Glucose: 120 mg/dL\n- HbA1c: 6.5%\n- BP: 130/85 mmHg"

        ciphertext = encryption_service.encrypt(plaintext)
        decrypted = encryption_service.decrypt(ciphertext)

        assert decrypted == plaintext
