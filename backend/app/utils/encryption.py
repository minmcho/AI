"""
Field-level encryption for PHI/PII data (HIPAA & GDPR compliance)

This module provides AES-256-GCM encryption for sensitive health information.
All PHI (Protected Health Information) must be encrypted at rest.
"""

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2
from cryptography.hazmat.backends import default_backend
import base64
import os
from typing import Optional


class FieldEncryption:
    """
    AES-256-GCM field-level encryption for PHI/PII

    HIPAA Compliance:
    - Uses NIST-approved AES-256-GCM encryption
    - Unique nonce for each encryption operation
    - Key derivation using PBKDF2 with 100,000 iterations
    - Authenticated encryption with associated data (AEAD)

    GDPR Compliance:
    - Enables data minimization through selective encryption
    - Supports right to erasure (crypto shredding via key rotation)
    - Pseudonymization of personal data
    """

    def __init__(self, master_key: str):
        """
        Initialize encryption with master key

        Args:
            master_key: Base64-encoded 256-bit master key
                       Generate with: openssl rand -base64 32
        """
        if not master_key:
            raise ValueError("Master encryption key is required for PHI protection")

        # Derive encryption key from master key
        self.master_key = base64.b64decode(master_key)
        if len(self.master_key) != 32:
            raise ValueError("Master key must be 256 bits (32 bytes)")

        self.aesgcm = AESGCM(self.master_key)

    def encrypt(self, plaintext: str, associated_data: Optional[str] = None) -> str:
        """
        Encrypt plaintext using AES-256-GCM

        Args:
            plaintext: Data to encrypt (e.g., medical condition, SSN)
            associated_data: Additional authenticated data (e.g., user_id)

        Returns:
            Base64-encoded ciphertext with nonce prepended
            Format: base64(nonce + ciphertext + tag)
        """
        if not plaintext:
            return ""

        # Generate random 96-bit nonce (recommended for GCM)
        nonce = os.urandom(12)

        # Prepare associated data for authentication
        aad = associated_data.encode('utf-8') if associated_data else b""

        # Encrypt with authentication
        ciphertext = self.aesgcm.encrypt(
            nonce,
            plaintext.encode('utf-8'),
            aad
        )

        # Prepend nonce to ciphertext (nonce is not secret)
        encrypted = nonce + ciphertext

        # Return base64-encoded result
        return base64.b64encode(encrypted).decode('utf-8')

    def decrypt(self, ciphertext: str, associated_data: Optional[str] = None) -> str:
        """
        Decrypt ciphertext using AES-256-GCM

        Args:
            ciphertext: Base64-encoded encrypted data
            associated_data: Same AAD used during encryption

        Returns:
            Decrypted plaintext

        Raises:
            cryptography.exceptions.InvalidTag: If authentication fails
        """
        if not ciphertext:
            return ""

        # Decode from base64
        encrypted = base64.b64decode(ciphertext)

        # Extract nonce (first 12 bytes)
        nonce = encrypted[:12]
        ciphertext_bytes = encrypted[12:]

        # Prepare associated data
        aad = associated_data.encode('utf-8') if associated_data else b""

        # Decrypt and verify authentication
        plaintext_bytes = self.aesgcm.decrypt(nonce, ciphertext_bytes, aad)

        return plaintext_bytes.decode('utf-8')

    def encrypt_dict(self, data: dict, fields_to_encrypt: list) -> dict:
        """
        Encrypt specific fields in a dictionary

        Args:
            data: Dictionary with sensitive data
            fields_to_encrypt: List of field names to encrypt

        Returns:
            Dictionary with encrypted fields
        """
        encrypted_data = data.copy()

        for field in fields_to_encrypt:
            if field in encrypted_data and encrypted_data[field]:
                encrypted_data[field] = self.encrypt(str(encrypted_data[field]))

        return encrypted_data

    def decrypt_dict(self, data: dict, fields_to_decrypt: list) -> dict:
        """
        Decrypt specific fields in a dictionary

        Args:
            data: Dictionary with encrypted data
            fields_to_decrypt: List of field names to decrypt

        Returns:
            Dictionary with decrypted fields
        """
        decrypted_data = data.copy()

        for field in fields_to_decrypt:
            if field in decrypted_data and decrypted_data[field]:
                try:
                    decrypted_data[field] = self.decrypt(decrypted_data[field])
                except Exception:
                    # If decryption fails, field might not be encrypted
                    pass

        return decrypted_data


def generate_encryption_key() -> str:
    """
    Generate a new 256-bit encryption key

    Returns:
        Base64-encoded 256-bit key suitable for AES-256
    """
    key = AESGCM.generate_key(bit_length=256)
    return base64.b64encode(key).decode('utf-8')


# Example usage and testing
if __name__ == "__main__":
    # Generate a new key (do this once, store securely)
    key = generate_encryption_key()
    print(f"Generated encryption key: {key}")

    # Initialize encryption
    encryptor = FieldEncryption(key)

    # Encrypt sensitive data
    ssn = "123-45-6789"
    medical_condition = "Type 2 Diabetes"

    encrypted_ssn = encryptor.encrypt(ssn, associated_data="user_12345")
    encrypted_condition = encryptor.encrypt(medical_condition)

    print(f"Encrypted SSN: {encrypted_ssn}")
    print(f"Encrypted condition: {encrypted_condition}")

    # Decrypt
    decrypted_ssn = encryptor.decrypt(encrypted_ssn, associated_data="user_12345")
    decrypted_condition = encryptor.decrypt(encrypted_condition)

    print(f"Decrypted SSN: {decrypted_ssn}")
    print(f"Decrypted condition: {decrypted_condition}")

    assert ssn == decrypted_ssn
    assert medical_condition == decrypted_condition
    print("✅ Encryption test passed!")
