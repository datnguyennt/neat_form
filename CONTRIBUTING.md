# Contributing to neat_form

Thank you for your interest in contributing to **neat_form**! We appreciate all forms of contributions, whether you are reporting a bug, proposing a new feature, improving documentation, or submitting a Pull Request (PR) to fix issues or optimize the codebase.

---

## 📋 1. Reporting Bugs

If you find a bug while using the library:
1. Search the [GitHub Issues](https://github.com/datnguyennt/neat_form/issues) list to check if it has already been reported or resolved.
2. If not, open a new Issue using the **Bug Report** template. Please provide:
   - A clear and concise description of the bug.
   - Steps to reproduce the behavior.
   - A minimal reproducible code example.
   - Environment details (Flutter/Dart versions, OS).

---

## 💡 2. Suggesting Features

We welcome ideas for improvements and new capabilities!
1. Create a new Issue using the **Feature Request** template.
2. Explain clearly:
   - What problem or use case you want to solve.
   - The proposed API design (if applicable).
   - The value or benefits this feature brings to the `neat_form` community.

---

## 🛠️ 3. Pull Request Process

If you would like to submit code changes or new features:

1. **Fork** this repository to your personal account and **Clone** it locally.
2. Create a new branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```
3. Make your modifications. Ensure you follow the project's core design:
   - Do not add any external package dependencies (Zero dependencies).
   - Write comprehensive unit tests in the `test/` directory to cover your changes.
4. Run static analysis and all tests to ensure the codebase remains clean and warning-free:
   ```bash
   flutter test --coverage
   dart analyze
   ```
5. Commit your changes with clear messages following the [Conventional Commits](https://www.conventionalcommits.org/) standard:
   ```bash
   git commit -m "feat: add validator X"
   # or
   git commit -m "fix: resolve edge case Y in form array"
   ```
6. Push the branch to your fork and open a **Pull Request** targeting the `main` branch of the original repository.
7. The maintainers will review your code and respond as soon as possible.
