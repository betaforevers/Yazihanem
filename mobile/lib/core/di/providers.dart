/// Global dependency injection using Riverpod providers.
library;

/// Provider hierarchy:
///   appConfigProvider
///     ├── secureStorageProvider
///     ├── localDbProvider
///     ├── apiClientProvider (depends on config + secureStorage)
///     ├── authStateProvider (depends on apiClient + secureStorage)
///     └── contentListProvider (depends on apiClient)
///
/// This file re-exports all global providers for convenience.

export 'package:yazihanem_mobile/core/api/api_client.dart'
    show apiClientProvider, appConfigProvider;
export 'package:yazihanem_mobile/core/storage/secure_storage.dart'
    show secureStorageProvider;
export 'package:yazihanem_mobile/core/storage/local_db.dart'
    show localDbProvider;
export 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart'
    show authStateProvider, authRepositoryProvider;
export 'package:yazihanem_mobile/features/content/providers/content_provider.dart'
    show contentListProvider, contentDetailProvider, contentRepositoryProvider;
