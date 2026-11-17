# Risk hotspots

A hit marks where a review reads hardest. It does not change the level, which is standaard unless
he asks for zwaar (see SKILL.md, "Pick the level"). A hit is a hit. Do not judge whether this
particular change is harmless before you have read it.

For a repo with a section of its own, run `scripts/risk-triggers <owner/repo> <n>`. It prints the
production line count first, then one line per hit. Only production files count, not tests, docs,
translations, seeders, factories or lockfiles, and only their code lines, not comments or blank lines. For any
other repo, hold the diff against the generic section yourself, and skip comments there too.

The triggers look at what a diff changes, not at where. A list of directories hit about 70% of all
PRs, because repositories, structures and validators are where every feature lands. Measured on
2026-10-08 over 881 PRs of the past year.

An entry earns its place with a source. When a review later turns out to have missed something, the
trigger that would have caught it goes on this list, with that miss as its source.

## Any repo

- Authentication and authorization code: login, tokens, sessions, permissions, roles, and the
  middleware that guards routes.
- Code that decides what a caller gets to see: tenant scoping, visibility flags, the parts of a
  serializer that differ per caller.
- A migration that changes existing columns or data. A new table is not a trigger.
- Money: invoices, payments, prices, discounts.
- Secrets and crypto: keys, encryption, vaults, signed URLs.
- Dependency manifests and their lock files.

## exonet/backend

| Trigger | Why | Source |
| --- | --- | --- |
| A changed line with `restrictForUser`, `restrictForContact`, `defaultScopes`, `#[Scope]` | Contact scoping. A repository without a contact variant fails open. | 55 fix PRs touched repositories, the access fixes among them (8117, 8149, 8411). `references/authorization-layers.md`, layers 3 and 4. |
| A changed line with `contactTransform`, `employeeRelations` | What a contact gets to see from a transformer. | 3 of 18 transformer fixes were visibility (8190, 8149, 7179). `references/authorization-layers.md`, layer 5. |
| A changed line with `->internal(`, `advancedRequestValidators` | The access risk in a structure sits here, not in the structure as a whole. | 3 leaks through `internal()`, filters and sorts (8015, 8088, 8190) and 7 authorization fixes in validators declared on structures (8134, 8189, 8300). |
| A changed line with `ExistsThroughRepository`, `exists:` | A plain `exists:` rule skips contact scoping. | Validators had the most security fixes, 14 (8410, 8389). `AGENTS.md` "Repository Binding and Access Scope (Critical)". |
| A changed line with `AclMiddleware`, any file in `Modules/Auth/` | The permission layer. Role 5 applies to every authenticated user. | 21 fix PRs in Auth (8189 privilege escalation, 8325). `references/authorization-layers.md`, layer 1. |
| A migration whose `up()` has `dropColumn`, `renameColumn`, `->change()`, `DB::`, `->update(`, `Schema::drop`, `dropIfExists`, `truncate` | Migrations are not routinely tested here, so the review is the main check. | Changes requested on 7721 and 7803, revert 8080. |
| Any file in `Modules/Finance/` | Money and the payment ledger. | The most fix PRs of any area, 52, and the highest fix share, 34% (8422, 8348). |
| Any file in `Modules/Secret/`, `Modules/SecureMessage/` | Customer secrets in a vault, encrypted messages. | Both modules are new in 2026, so there is little history yet. `AGENTS.md` module index. |
| `Modules/Core/Utilities/RepositoryBinding.php`, `Modules/Core/Validators/ExistsThroughRepository.php`, `Modules/Core/Repositories/AbstractCoreRepository.php` | The mechanisms every contact restriction runs through. A change here can open every module at once without naming a keyword. | 8411 changed `ExistsThroughRepository.php` and the keyword triggers missed it. `references/authorization-layers.md`, layer 3. |
| Any file in `Modules/SupportToken/`, `Modules/FrontPage/` | Limited-access support tokens, and the customer portal's sessions and password reset. | `AGENTS.md` module index. |
| Any file in `Modules/Search/`, `Modules/Webhooks/` | Few PRs, but most were access, DoS or signing fixes. | 3 of the 4 Search PRs (8181, 8313, 8436), Webhooks 8348, 8349. |
| `composer.json`, `composer.lock`, `package.json`, `package-lock.json` | Dependency changes need approval. | `AGENTS.md` "Do not change the application's dependencies without approval". |
