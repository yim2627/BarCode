# Releasing

Cutting a new release is one command:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z — short summary"
git push origin vX.Y.Z
```

The `Build & Release DMG` workflow then:

1. Builds `BarCode.dmg` with `CFBundleShortVersionString` stamped to `X.Y.Z`.
2. Publishes it to the GitHub Releases page.
3. **(Optional)** Bumps the `yim2627/homebrew-tap` cask formula (`version` and `sha256`) and pushes the change so `brew upgrade --cask barcode` picks the new release up automatically.

Step 3 is gated behind a Personal Access Token. Without it, the workflow still ships the DMG; you'd just bump the tap by hand. To enable the automatic tap bump:

## One-time secret setup

1. Visit <https://github.com/settings/personal-access-tokens/new> (fine-grained PAT).
2. **Resource owner**: your account (`yim2627`).
3. **Repository access**: *Only select repositories* → choose `yim2627/homebrew-tap`.
4. **Permissions**: under *Repository permissions*, set **Contents** to *Read and write*. Leave everything else alone.
5. Pick a long-ish expiration (1 year is fine; rotate later).
6. Generate the token and copy it.
7. In **this** repo (`yim2627/BarCode`) → Settings → Secrets and variables → Actions → *New repository secret*:
   - Name: `TAP_GH_TOKEN`
   - Value: paste the token you just generated.

That's it. The next tag push will both publish a release and bump the cask.

## What does the bump look like?

```ruby
# Casks/barcode.rb (in homebrew-tap)
version "0.2.2"
sha256 "9b43166680c677c3d94e307a737c0e1caec9137c14a60ba82fc4c047fba93531"
```

becomes

```ruby
version "0.2.3"
sha256 "<new sha256>"
```

via a `sed` replace, committed by `github-actions[bot]`.

## Manual fallback

If the workflow's tap bump fails or you skip the secret, bump the formula by hand:

```bash
SHA256=$(curl -fsSL https://github.com/yim2627/BarCode/releases/download/vX.Y.Z/BarCode.dmg \
  | shasum -a 256 | awk '{print $1}')

cd ~/path/to/homebrew-tap
sed -i '' \
  -e 's|^  version ".*"|  version "X.Y.Z"|' \
  -e "s|^  sha256 \".*\"|  sha256 \"${SHA256}\"|" \
  Casks/barcode.rb
git commit -am "chore(barcode): bump to X.Y.Z" && git push
```
