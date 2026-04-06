/*
 * shim.c — Empty C source so SPM recognizes this as a C-language target.
 *
 * The actual C++ implementation lives in BonhommeAccel/ and is linked
 * as a pre-built static library or compiled alongside via Xcode.
 *
 * For SPM-only builds, this target provides the BonhommeAccel.h header
 * via the module.modulemap so that Swift code can `import clibBonhommeAccel`.
 */
