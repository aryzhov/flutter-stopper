# Stopper

A bottom sheet that can be expanded to one of the pre-defined stop heights by dragging.

![animated image](https://github.com/aryzhov/flutter-stopper/blob/master/doc/stopper_demo.gif?raw=true)     

## Introduction

Some iOS applications have a bottom sheet that has two states: half-expanded and fully expanded.
The standard `showBottomSheet` method lacks such a capability. The complexity in implementing this 
behavior arises when the the bottom sheet needs to be scrollable, making scroll and drag 
event handling difficult as these gestures can be used for scrolling the list as well as
for dragging the bottom sheet up/down, depending on the position of the bottom sheet and the current 
scroll position. The *Stopper* plugin addresses this problem by:

- Letting the developer define discreet height values (stops) to which the bottom sheet can be expanded;
- Using the builder pattern to build the bottom sheet depending on the current stop value;
- Instantiating `ScrollController` and `ScrollPhysics` objects and passing them to the 
  bottom sheet builder;
- Using animations to make transitions of the bottom sheet between the stops look natural;
- Providing a convenient `showStopper` function to be used instead of `showBottomSheet` in 
  order to handle dismissal of the bottom sheet by the user.

This plugin utilizes bottom sheet functionality from the `Scaffold`
widget and avoids copy/paste from the standard library, making the implementation clear and
easy to maintain.

## Example

```dart
import 'package:stopper/stopper.dart';
//...
final height = MediaQuery.of(context).size.height;
//...
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
            //...
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
