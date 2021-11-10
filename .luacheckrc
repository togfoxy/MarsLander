-- .luacheckrc configuration file

-- Standard globals
std = "max+love"

-- Allow defined globals
allow_defined = true

-- disable warnings about secondary unused variables
unused_secondaries = false

-- Exclude libraries: we don't really care about those
exclude_files = {"**/lib/**"}
