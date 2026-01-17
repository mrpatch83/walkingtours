Quick setup notes

1) Install Flutter on macOS: https://flutter.dev/docs/get-started/install/macos
2) Install GitHub CLI (optional, for creating a repo remotely): https://cli.github.com/

To complete the project scaffold after installing Flutter run:

```bash
cd walking_tour_app
flutter pub get
flutter create .
flutter run
```

To create a GitHub repo (if `gh` installed & authenticated):

```bash
cd walking_tour_app
gh repo create <repo-name> --public --source=. --remote=origin --push
```

Or add a remote manually and push:

```bash
git remote add origin git@github.com:USERNAME/REPO.git
git branch -M main
git push -u origin main
```
