# stopper

A bottom sheet that can be expanded to one of pre-defined stop heights by dragging.

## Introduction

Some iOS applications have a bottom sheet that has two states: half-expanded and fully expanded.
The standard `showBottomSheet` method such capability. A complication in implementing this 
behavior occurs arises if the contents of the bottom sheet is scrollable, making scroll and drag 
events context-dependent. This plugin addresses this problem by:

- Letting the developer define discreet height values (stops) to which the bottom sheet can be expanded;
- Using a builder pattern to build the contents of the bottom sheet, depending on the current stop value;
- Passing `ScrollController` and `ScrollPhysics` objects that can be passed to a scrollable widget that
  exists in the contents;
- Using animations to make the transitions of the bottom sheet between stops look natural;
- Providing a convenient `showStopper` function to be used instead of `showBottomSheet` in 
  order to handle the dismissal of bottom sheet by the user.

## Example

```dart
import 'package:stopper/stopper.dart';
///...
final height = MediaQuery.of(context).size.height;
///...
MaterialButton(
  child: Text("Show Stopper"),
  onPressed: () {
    showStopper(
      stops: [0.5 * height, height],
      builder: (context, scrollController, scrollPhysics, stop) {
        return ListView(
          controller: scrollController,
          physics: scrollPhysics,
          children: [
            ///...
          ]
        );
      }
    );
  },
  ...
)
```
