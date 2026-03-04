# SaaS ERP Layout & Architecture Rules

# Antigravity UI Stability Doctrine

## Version 4.0 — Zero Overflow Architecture Standard (Web-First Hardened)

---

# 0️⃣ Core Philosophy

Antigravity does not “fix” layout errors.
Antigravity designs layouts that make layout errors impossible.

Every screen must be:

* Constraint-aware
* Width-bounded
* Flex-safe
* Scroll-safe
* Sliver-safe
* Web-safe
* Desktop-stable
* Text-scale resilient

If a widget can overflow, it must be hardened.

---

# 1️⃣ THE WEB-SAFE CENTERING MASTER PATTERN

For login screens, landing pages, onboarding, or any centered form.

## Mandatory Structure

* Use `Stack` at the root of `Scaffold.body`
* `Positioned.fill` for background
* `SafeArea → Center → SingleChildScrollView`
* Inside scroll view: `ConstrainedBox(maxWidth)`
* Primary `Column` must use `mainAxisSize: MainAxisSize.min`

```dart
return Scaffold(
  body: Stack(
    children: [
      Positioned.fill(child: MyBackground()),

      SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [...],
              ),
            ),
          ),
        ),
      ),

      if (isLoading)
        Positioned.fill(child: MyLoadingOverlay()),
    ],
  ),
);
```

## Critical Rule

Center must be outside SingleChildScrollView.

Never reverse that order.

---

# 2️⃣ GLOBAL FLEX SAFETY RULE (AG-FLEX-01)

## 🚨 Mandatory For Entire Codebase

Whenever using `Row` with `Text` inside constrained width:

ALWAYS wrap `Text` with `Flexible`
ALWAYS use `TextOverflow.ellipsis`

### ❌ Forbidden Pattern

```dart
Row(
  children: [
    Icon(Icons.add),
    SizedBox(width: 8),
    Text("Add School"), // Illegal in Antigravity
  ],
)
```

### ✅ Required Pattern

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.add),
    SizedBox(width: 6),
    Flexible(
      child: Text(
        "Add School",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

## Why This Exists

Flutter does NOT auto-shrink text in Row.

Without Flexible:

* Text demands natural width
* Parent gives less
* RenderFlex overflow
* Yellow/black stripe
* Web instability

This rule applies to:

* Buttons
* Table cells
* Dialog actions
* Sidebar items
* Chips
* Headers
* Filter bars
* Action toolbars

---

# 3️⃣ BUTTON ARCHITECTURE STANDARD (AG-BTN-01)

All buttons must:

* Use `mainAxisSize: MainAxisSize.min`
* Wrap text in `Flexible`
* Use ellipsis
* Avoid fixed widths unless intentional

### Official Antigravity Button Pattern

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    if (icon != null) ...[
      icon,
      SizedBox(width: 6),
    ],
    Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

Buttons must never overflow inside:

* DataTable
* Sidebar compact mode
* Responsive layouts
* Dialogs

---

# 4️⃣ WIDTH CONSTRAINT RULE (AG-WIDTH-01)

Never use:

```dart
width: double.infinity
```

Inside:

* SliverToBoxAdapter
* CustomScrollView
* Unbounded contexts

Instead use bounded constraints:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: constraints.maxWidth,
      ),
      child: ...
    );
  },
);
```

---

# 5️⃣ SLIVER DASHBOARD PATTERN (AG-SLIVER-01)

For dashboards and mixed scroll screens:

* Use ONE `CustomScrollView`
* Never nest scroll systems
* Never use shrinkWrap inside scroll

## Official Pattern

```dart
return CustomScrollView(
  slivers: [

    SliverToBoxAdapter(child: DashboardHeader()),

    SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverGrid(
        delegate: SliverChildListDelegate([...]),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getCrossAxisCount(),
          childAspectRatio: 1.5,
        ),
      ),
    ),

    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: 5,
        itemBuilder: (context, index) => ListTile(...),
        separatorBuilder: (_, __) => Divider(),
      ),
    ),
  ],
);
```

---

# 6️⃣ DATA TABLE STABILITY RULE (AG-TABLE-01)

DataTable must always be wrapped in horizontal scroll:

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(...),
)
```

Inside table cells:

* No Expanded
* No double.infinity
* Buttons must follow AG-BTN-01
* Row + Text must follow AG-FLEX-01

---

# 7️⃣ COLUMN & EXPANDED RULE (AG-COL-01)

Never use Expanded inside:

* Scroll views
* SliverToBoxAdapter
* Parents without fixed height

Expanded requires finite height.

If height is not guaranteed finite → Expanded is illegal.

---

# 8️⃣ NESTED SCROLL RULE (AG-SCROLL-01)

Forbidden:

* ListView inside SingleChildScrollView
* GridView inside SingleChildScrollView
* shrinkWrap: true inside scroll

Allowed:

* CustomScrollView with Slivers
* OR SingleChildScrollView with Column
* Never both

---

# 9️⃣ RESPONSIVE SAFETY RULE (AG-RESP-01)

Every screen must be stable at:

* 320px width
* Tablet width
* Ultra-wide desktop

Test:

* Browser resize
* Text scale factor 1.3x
* Sidebar expanded and collapsed

If overflow appears → AG-FLEX-01 violation.

---

# 🔟 ANTI-PATTERN BLACKLIST

The following are banned in Antigravity:

❌ Row + Text without Flexible
❌ Expanded inside scroll without bounded height
❌ double.infinity inside Sliver
❌ shrinkWrap ListView inside scroll
❌ Nested scroll systems
❌ SliverFillRemaining(hasScrollBody: false) for centering
❌ LayoutBuilder wrapping entire screen without responsive reason
❌ Raw DataTable without horizontal scroll

---

# 1️⃣1️⃣ PRE-MERGE SCREEN CHECKLIST

Before merging any new screen:

* Resize to 320px width
* Resize to ultra-wide
* Test inside dialog
* Test inside DataTable
* Enable text scaling
* Look for yellow overflow stripes

If stripe appears → block merge.

---

# 1️⃣2️⃣ DESIGN SYSTEM STABILITY NOTE

Atomic widgets (AppButton, AppCard, etc.) must be:

* Flex-safe
* Constraint-aware
* Overflow-proof

Design system widgets must assume they will be used in tight containers.

---

# Final Declaration

Antigravity UI Stability Doctrine v4.0

Goal:
Zero RenderFlex overflow
Zero constraint assertion
Zero nested scroll conflict
Zero unbounded width crash

Architecture prevents errors before they exist.
