# Enhanced User Management Implementation

This document describes the enhanced user management system implemented to match the Next.js web app's hierarchical permission system.

## Overview

The implementation adds a sophisticated module-based permission system with hierarchical structure similar to the Next.js web app, featuring:

1. **Module-level permissions** (Accounting, Warehouse, Sales, Purchases, Users)
2. **Sub-page permissions** within each module
3. **Tab-based navigation** (Users & Permissions tabs)
4. **Enhanced access management UI** with drill-down capability
5. **Runtime permission checking service**

## Key Components

### 1. Data Models (`user_management_controller.dart`)

#### New Models Added:

- **`ModulePermission`**: Represents module-level access control
  ```dart
  class ModulePermission {
    final String module;
    final String displayName;
    final bool hasAccess;
    final bool canView;
    final IconData icon;
  }
  ```

- **`SubPagePermission`**: Represents sub-page access within modules
  ```dart
  class SubPagePermission {
    final String page;
    final String displayName;
    final bool canView;
  }
  ```

- **`ModuleConfig`**: Defines module structure with sub-pages
  ```dart
  class ModuleConfig {
    final String module;
    final String displayName;
    final IconData icon;
    final List<SubPagePermission> subPages;
  }
  ```

#### Module Configurations:

The system includes 5 main modules with their respective sub-pages:

1. **Accounting** (24 sub-pages): Dashboard, Chart of Accounts, Bank Accounts, Journal Entries, General Ledger, etc.
2. **Warehouse** (8 sub-pages): Products, Categories, Suppliers, Stock Movement, etc.
3. **Sales** (10 sub-pages): Dashboard, Products, Orders, Quotations, Customers, etc.
4. **Purchases** (7 sub-pages): Dashboard, Purchase Orders, Goods Receiving, etc.
5. **Users** (3 sub-pages): User Management, Roles, Permissions

### 2. Controller Enhancements (`user_management_controller.dart`)

#### New Methods:

- **`initializeModulePermissions(User user)`**: Loads and initializes permissions for a user
- **`updateModuleAccess(String module, bool hasAccess)`**: Updates module-level access
- **`updateSubPagePermission(String module, String subPage, bool canView)`**: Updates sub-page permissions
- **`buildPermissionsList(String userId)`**: Converts current state to API format
- **`setRoleFilter(String role)`**: Added role filtering support

#### Permission Storage:

```dart
final RxMap<String, ModulePermission> modulePermissions = <String, ModulePermission>{}.obs;
final RxMap<String, Map<String, SubPagePermission>> subPagePermissions = <String, Map<String, SubPagePermission>>{}.obs;
```

### 3. Enhanced Access Management Screen (`enhanced_access_management_screen.dart`)

A new screen that provides hierarchical permission management:

#### Features:

- **User info header**: Shows selected user details
- **Module list view**: Shows all modules with access toggles
- **Sub-page drill-down**: Tap on enabled modules to configure sub-page access
- **Navigation**: Back button to return to module view
- **Save functionality**: Persists permissions to API

#### UI Structure:

```
User Info Header
├── Avatar
├── Name & Email
└── Role Badge

Module List (when no module selected)
├── Module Card 1 (Accounting)
│   ├── Icon
│   ├── Name
│   ├── Sub-page count
│   └── Access Toggle
├── Module Card 2 (Warehouse)
└── ...

Sub-page List (when module selected)
├── Module Info Header
└── Sub-page Cards
    ├── Sub-page 1
    │   ├── Icon
    │   ├── Name
    │   └── Access Toggle
    └── ...
```

### 4. Updated User List Screen (`user_list_screen.dart`)

#### Changes:

- **Tab navigation**: Added "Users" and "Permissions" tabs
- **Enhanced filtering**: Added role filter to existing status filter
- **Permissions tab**: Shows module overview with sub-page counts
- **Updated menu**: Links to new enhanced access management screen

#### Tab Structure:

```dart
TabBarView(
  children: [
    _buildUsersTab(),      // Original user list
    _buildPermissionsTab(), // New module overview
  ],
)
```

### 5. Permission Service (`permission_service.dart`)

A runtime service for checking user permissions throughout the app.

#### Methods:

- **`hasPermission(String page)`**: Check access to specific page
- **`hasModuleAccess(String module)`**: Check access to entire module
- **`hasSubPageAccess(String module, String subPage)`**: Check sub-page access
- **`hasAnyModuleAccess()`**: Check if user has any permissions
- **`getAccessibleModules()`**: Get list of accessible modules
- **`getAccessibleSubPages(String module)`**: Get accessible sub-pages for a module
- **`isAdmin`**: Quick admin check

#### Usage Example:

```dart
class SomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService.to;
    
    if (!permissionService.hasModuleAccess('accounting')) {
      return AccessDeniedScreen();
    }
    
    // Build screen for accounting module
  }
}
```

## Permission Flow

### 1. User Selection Flow:

```
User List Screen
  ↓ (Tap "Manage Access")
Enhanced Access Management Screen
  ↓ (Shows module overview)
User selects module access
  ↓ (Tap on enabled module)
Sub-page configuration view
  ↓ (Configure sub-page access)
Save permissions
```

### 2. Permission Storage Format:

Permissions are stored in the hierarchical format:

```
Module-level: "accounting" → { canView: true }
Sub-page-level: "accounting-journal-entries" → { canView: true }
```

### 3. Permission Loading:

When a user is selected:

1. Reset all permissions to false
2. Initialize module configurations
3. Parse existing user permissions
4. Match module-level permissions
5. Match sub-page permissions (format: `module-subpage`)
6. Update UI state

## API Integration

The system maintains compatibility with the existing API:

- **Load users**: `GET /api/admin/users`
- **Load roles**: `GET /api/admin/users/roles`
- **Update permissions**: `PUT /api/admin/users/{userId}/permissions`

The permission format sent to API:

```json
{
  "permissions": [
    {
      "page": "accounting",
      "canView": true,
      "canCreate": false,
      "canEdit": false,
      "canDelete": false
    },
    {
      "page": "accounting-journal-entries",
      "canView": true,
      "canCreate": false,
      "canEdit": false,
      "canDelete": false
    }
  ]
}
```

## Usage Integration

### 1. Initialize Permission Service:

In your main.dart or app initialization:

```dart
void main() async {
  await Get.putAsync(() => PermissionService().init());
  runApp(MyApp());
}
```

### 2. Check Permissions in Screens:

```dart
class JournalEntriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService.to;
    
    if (!permissionService.hasSubPageAccess('accounting', 'journal-entries')) {
      return AccessDeniedWidget();
    }
    
    // Build journal entries UI
  }
}
```

### 3. Control Navigation Based on Permissions:

```dart
// In your drawer/route configuration
final permissionService = PermissionService.to;

if (permissionService.hasModuleAccess('accounting')) {
  navigationItems.add(
    NavigationItem(
      title: 'Accounting',
      icon: Icons.account_balance,
      route: '/accounting/dashboard',
    ),
  );
}
```

## Comparison with Next.js Implementation

| Feature | Next.js | Flutter Implementation |
|---------|---------|----------------------|
| Module-based permissions | ✅ | ✅ |
| Sub-page permissions | ✅ | ✅ |
| Tab navigation | ✅ | ✅ |
| User selection flow | ✅ | ✅ |
| Drill-down UI | ✅ | ✅ |
| Search & filters | ✅ | ✅ |
| Runtime permission checking | ✅ | ✅ |
| Permission service | ✅ | ✅ |

## Benefits

1. **Granular Control**: Admins can control access at both module and sub-page levels
2. **Scalable Structure**: Easy to add new modules and sub-pages
3. **User-Friendly UI**: Intuitive drill-down interface
4. **Runtime Checks**: Permission service for consistent access control
5. **API Compatible**: Works with existing backend structure
6. **Type Safety**: Strongly typed permission models

## Future Enhancements

Potential improvements for future iterations:

1. **Permission Templates**: Pre-defined permission sets for common roles
2. **Bulk Operations**: Apply permissions to multiple users at once
3. **Permission Inheritance**: Sub-pages inherit module access automatically
4. **Audit Logging**: Track permission changes
5. **Time-based Permissions**: Temporary access grants
6. **Custom Modules**: Allow dynamic module configuration

## Files Modified/Created

### Modified:
- `lib/core/Users/controller/user_management_controller.dart`
- `lib/core/Users/screen/user_list_screen.dart`

### Created:
- `lib/core/Users/screen/enhanced_access_management_screen.dart`
- `lib/core/Users/service/permission_service.dart`
- `lib/core/Users/README_IMPLEMENTATION.md` (this file)

## Testing Recommendations

1. **User Management Flow**:
   - Create a new user
   - Navigate to access management
   - Enable module access
   - Configure sub-page permissions
   - Save and verify persistence

2. **Permission Checks**:
   - Test permission service methods
   - Verify access control in protected screens
   - Test admin bypass functionality

3. **UI Testing**:
   - Test tab navigation
   - Verify drill-down functionality
   - Test back navigation
   - Verify permission toggle states

4. **Edge Cases**:
   - User with no permissions
   - Admin user (should have all access)
   - Invalid user IDs
   - Network errors during save