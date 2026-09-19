#!/usr/bin/env python3
"""Offline signing-policy regressions; fixtures contain no real credentials."""
import datetime as dt
import subprocess
import unittest
from unittest.mock import patch

from cloud_signing import TEAM, BUNDLES, TARGETS, signing_config, validate_profile, run


class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.now = dt.datetime(2026, 9, 19, tzinfo=dt.timezone.utc)
        self.bundle = 'com.natural.Bonhomme'
        self.cert = b'synthetic certificate bytes, not a usable certificate'
        self.profile = {
            'Name': self.bundle, 'UUID': '87083C4B-E51F-4CCA-A10B-40AC00000001',
            'TeamIdentifier': [TEAM], 'ApplicationIdentifierPrefix': [TEAM], 'Platform': ['iOS'],
            'CreationDate': self.now - dt.timedelta(days=1),
            'ExpirationDate': self.now + dt.timedelta(days=30),
            'DeveloperCertificates': [self.cert],
            'Entitlements': {'application-identifier': TEAM + '.' + self.bundle,
                             'com.apple.developer.team-identifier': TEAM, 'get-task-allow': False},
        }

    def validate(self, **kwargs):
        return validate_profile(self.profile, self.bundle, 'iOS', self.cert, now=self.now, **kwargs)

    def test_current_store_profile(self):
        self.validate()

    def test_legacy_app_id_prefix_is_not_confused_with_team(self):
        self.profile['ApplicationIdentifierPrefix'] = ['OLDPREFIX1']
        self.profile['Entitlements']['application-identifier'] = 'OLDPREFIX1.' + self.bundle
        self.validate()

    def test_wrong_team(self):
        self.profile['TeamIdentifier'] = ['WRONGTEAM1']
        with self.assertRaisesRegex(ValueError, 'team mismatch'): self.validate()

    def test_wrong_entitlement_team(self):
        self.profile['Entitlements']['com.apple.developer.team-identifier'] = 'WRONGTEAM1'
        with self.assertRaisesRegex(ValueError, 'team mismatch'): self.validate()

    def test_name_must_resolve_per_target(self):
        self.profile['Name'] = 'Generic App Store Profile'
        with self.assertRaisesRegex(ValueError, 'Name must equal'): self.validate()

    def test_expired_or_nearly_expired(self):
        for hours in (-1, 0, 12, 24):
            self.profile['ExpirationDate'] = self.now + dt.timedelta(hours=hours)
            with self.assertRaisesRegex(ValueError, '24 hours'): self.validate()

    def test_future_profile(self):
        self.profile['CreationDate'] = self.now + dt.timedelta(hours=1)
        with self.assertRaisesRegex(ValueError, 'not yet valid'): self.validate()

    def test_ad_hoc_and_development_rejected_even_empty_device_list(self):
        self.profile['ProvisionedDevices'] = []
        with self.assertRaisesRegex(ValueError, 'App Store profile'): self.validate()

    def test_enterprise_or_developer_id_rejected(self):
        self.profile['ProvisionsAllDevices'] = True
        with self.assertRaisesRegex(ValueError, 'App Store profile'): self.validate()

    def test_debugging_rejected(self):
        self.profile['Entitlements']['get-task-allow'] = True
        with self.assertRaisesRegex(ValueError, 'debugging'): self.validate()

    def test_wildcard_and_wrong_identifier(self):
        for identifier in (TEAM + '.*', TEAM + '.com.someone.else'):
            self.profile['Entitlements']['application-identifier'] = identifier
            with self.assertRaisesRegex(ValueError, 'exact bundle ID'): self.validate()

    def test_wrong_platform(self):
        self.profile['Platform'] = ['tvOS']
        with self.assertRaisesRegex(ValueError, 'platform mismatch'): self.validate()

    def test_wrong_or_extra_certificate(self):
        for certificates in ([b'wrong cert'], [self.cert, self.cert]):
            self.profile['DeveloperCertificates'] = certificates
            with self.assertRaisesRegex(ValueError, 'selected distribution certificate'): self.validate()

    def test_missing_group_capability(self):
        with self.assertRaisesRegex(ValueError, 'required capability'):
            self.validate(required_entitlements={'com.apple.security.application-groups': ['group.com.natural.Bonhomme']})

    def test_push_must_be_production(self):
        self.profile['Entitlements']['aps-environment'] = 'development'
        with self.assertRaisesRegex(ValueError, 'required capability'):
            self.validate(required_entitlements={'aps-environment': 'development'})
        self.profile['Entitlements']['aps-environment'] = 'production'
        self.validate(required_entitlements={'aps-environment': 'development'})

    def test_mac_identifier_and_unrestricted_sandbox(self):
        self.profile['Platform'] = ['OSX']
        self.profile['Entitlements']['com.apple.application-identifier'] = self.profile['Entitlements'].pop('application-identifier')
        validate_profile(self.profile, self.bundle, 'OSX', self.cert, now=self.now,
                         required_entitlements={'com.apple.security.app-sandbox': True})

    def test_watch_legacy_ios_profile(self):
        validate_profile(self.profile, self.bundle, 'watchOS', self.cert, now=self.now)

    def test_invalid_uuid_cannot_become_install_path(self):
        self.profile['UUID'] = '../../other-file'
        with self.assertRaisesRegex(ValueError, 'Invalid profile UUID'): self.validate()

    def test_failed_secret_command_is_redacted(self):
        result = subprocess.CompletedProcess(['security'], 1, b'PRIVATE', b'PRIVATE')
        with patch('cloud_signing.subprocess.run', return_value=result):
            with self.assertRaises(ValueError) as context:
                run(['security', 'import', '-P', 'PRIVATE'])
        self.assertNotIn('PRIVATE', str(context.exception))


class ConfigTests(unittest.TestCase):
    def test_each_shipping_target_has_exact_profile(self):
        for platform, bundles in BUNDLES.items():
            config = signing_config(platform, 'A' * 40, '/tmp/keychain')
            mappings = dict(line.split(' = ', 1) for line in config.splitlines() if line.startswith('NATURAL_PROFILE_'))
            self.assertEqual(mappings, {'NATURAL_PROFILE_' + TARGETS[bundle]: bundle for bundle in bundles})
            self.assertIn('PROVISIONING_PROFILE_SPECIFIER = $(NATURAL_PROFILE_$(TARGET_NAME))', config)

    def test_package_bundle_is_not_assigned_a_profile(self):
        config = signing_config('ios', 'A' * 40, '/tmp/keychain')
        self.assertNotIn('NATURAL_PROFILE_BonhommeCore_BonhommeCore =', config)
        self.assertNotIn('PROVISIONING_PROFILE_SPECIFIER = $(PRODUCT_BUNDLE_IDENTIFIER)', config)


if __name__ == '__main__':
    unittest.main()
