# Stopper

A bottom sheet that can be expanded to one of pre-defined stop heights by dragging.

## Introduction

Some iOS applications have a bottom sheet that has two states: half-expanded and fully expanded.
The standard `showBottomSheet` method lacks such a capability. A complication in implementing this 
behavior arises if the the bottom sheet is scrollable, making scroll and drag 
events context-dependent. The *Stopper* plugin addresses this problem by:

- Letting the developer define discreet height values (stops) to which the bottom sheet can be expanded;
- Using the builder design pattern to build the bottom sheet, depending on the current stop value;
- Passing `ScrollController` and `ScrollPhysics` objects that can be passed to a scrollable view
  inside the bottom sheet;
- Using animations to make transitions of the bottom sheet between the stops look natural;
- Providing a convenient `showStopper` function to be used instead of `showBottomSheet` in 
  order to handle the dismissal of bottom sheet by the user.

![animated image](https://github.com/aryzhov/flutter-stopper/blob/master/docs/stopper_demo.mp4?raw=true)     

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
      context: context,
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

*Note:* The build context passed to `showStopper` must have a `Scaffold` widget as an ancestor. 
Therefore it's recommended to use `Builder` to build the body of the Scaffold. See
the complete example app provided in this package for details on this approach.
