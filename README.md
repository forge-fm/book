# Logic for Systems (CSCI 1710) Textbook

## Building with MkDocs (Recommended)

### Setup

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the migration script (converts mdbook admonish syntax to MkDocs format):
   ```bash
   chmod +x migrate.sh
   ./migrate.sh
   ```

3. Preview locally:
   ```bash
   mkdocs serve
   ```

### Year-Based Versioning with Mike

This book uses `mike` for year-based versioning (e.g., 2025, 2026).

#### Branch Strategy

- `main` branch: Current year's content (e.g., 2026)
- `book/2025` branch: Frozen 2025 version

#### Local Preview with Versions

```bash
# Deploy versions locally
mike deploy 2025
mike deploy 2026 latest
mike set-default latest

# Preview with version dropdown
mike serve
```

#### Publishing to GitHub Pages

```bash
# First deployment (from main branch for 2026)
mike deploy --push 2026 latest
mike set-default --push latest

# To update a past year (checkout that branch first)
git checkout book/2025
mike deploy --push 2025
```

#### How It Works

- Source markdown lives in git branches (e.g., `main` for 2026, `book/2025` for 2025)
- Built HTML is committed to `gh-pages` branch with version subdirectories
- Version dropdown in the site reads from `versions.json` file
- Root `/` redirects to the default version (latest)

### Commands Reference

| Command | Description |
|---------|-------------|
| `mkdocs serve` | Preview without versions |
| `mkdocs build` | Build without versions |
| `mike deploy <version> [alias]` | Build and stage a version |
| `mike set-default <version>` | Set landing page redirect |
| `mike serve` | Preview with version dropdown |
| `mike list` | List all deployed versions |
| `mike deploy --push <version>` | Deploy to remote gh-pages |

---

## Building with mdBook (Legacy)

1. Install Rust and Cargo from [here](https://rust-lang.github.io/mdBook/guide/installation.html#:~:text=Rust%20installation%20page).
2. Run `cargo install mdbook`
3. Run `cargo install mdbook-admonish`
4. Run `cargo install mdbook-katex`
5. `cd book` and `mdbook serve --open` to open the docs in a browser. `mdbook` will automatically rebuild the output _and_ automatically refresh your web browser when changes are made.

Check out the rest of the docs here: https://rust-lang.github.io/mdBook/guide/creating.html

## Credits

The `mdbook` frame of this book is based on the `mdbook` version of the Forge documentation initiated by HTA David Fryd.

The MkDocs migration was created to support year-based versioning for course iterations.
