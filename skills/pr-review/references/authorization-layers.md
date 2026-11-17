# Authorization layers in exonet/backend

Read this when a review touches access code (see the exonet/backend rows of `risk-hotspots.md`) or
when a finding claims that one customer can reach another's data.

Judging whether an endpoint leaks another customer's data requires checking **five** stacked layers,
not three. Checking only the first three produces confident false positives.

1. **Permission.** `AclMiddleware` calls `app('acl')->has($permissionName)` and fails closed. The
   name is the URL path with `{param}` → `details`, `relationships` dropped, and the method appended
   (`customers/{customer}/notes` GET → `customers.details.notes.get`). **Trap:**
   `PermissionQueries::getRoleIdsForUser()` has `->orWhere('roles.id', 5)` *outside* the user filter,
   so role 5 `basic_user` applies to every authenticated user (bots and external contacts included)
   as long as `user_roles` has any row. For anything role 5 carries, this layer is not a gate.
2. **Scope.** Skipped entirely when the token has no scopes (`!empty($token->scopes)`). Not a
   backstop.
3. **Repository binding.** `RepositoryBinding` does `$repository[$authType] ?? $repository['base']`,
   so a resource without a `contact` variant hands an external caller the unscoped base repository.
   **Fails open.**
4. **Model default scopes.** `$defaultScopes` on the repository, resolved as `#[Scope]` methods on the
   entity. This is what protects access tokens (`OauthAccessTokenData::forUser()` limits a
   non-internal caller to their own tokens whatever the id in the URL). Per model and opt-in, so check
   that it is there, never assume it.
5. **Transformer.** A `contactTransform()` can refuse outright. `CommentTransformer::contactTransform()`
   has return type `never` and throws `UnauthorizedException`.

`permission_groups.public` is **not** part of the ACL chain. It only controls what the contact
`PermissionGroupRepository` lists through the API. Using it as a proxy for "can an external user
hold this permission" is wrong in both directions.

Bots (`UserType::Bot`) deliberately get the base, unscoped repository through the `RepositoryBinding`
fallback, and the transformer treats them as employees. That is by design, so never raise it as a
finding. Only a change to bot handling itself is worth a mention.

Whether an endpoint leaks is a property of the **code**, so a local finding applies to production too.
Permission assignment only decides *who* can trigger it. The only reliable proof is a real call as an
external contact, with a valid hashid of a parent that contact cannot see, after confirming with an
employee token that the parent actually has children. Otherwise "0 records" is ambiguous.

Measured on 2026-08-03: all 405 relation GET endpoints called that way as an external contact gave
0 leaks (359 protected by a real call, 3 by a contact repository, 43 unreachable for customers).
