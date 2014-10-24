# TMInstanceMethodSwizzler & TMTimeoutManager

[![Build Status](https://travis-ci.org/jplana/TMInstanceMethodSwizzler.svg?branch=master)](https://travis-ci.org/jplana/TMInstanceMethodSwizzler)

`TMInstanceMethodSwizzler` is a class which allows you to replace or modify an object's method implementation without affecting any other objects of the same class and without side effects either. It might be useful, for instance, to implement Aspect Oriented Programing and to create partial object mocks for testing. You can whatch this [YouTube video](http://www.youtube.com/watch?v=VS9gWhZUpVg) to know about it in greater detail.

`TMTimeoutManager` is an example of use of the previous, which allows you to observe an object's method to be called before a certain timeout and specifying different blocks of code to be invoked depending on whether the method is called or not.

Both are the result of a [Hack me up](http://www.youtube.com/watch?v=IH9m1gt9AHg), an internal contest where Tuenti engineers are given 24 hours to develop whatever they think that might be useful, funny or worth making.

## Installing

### Using CocoaPods

1. Include the following line in your `Podfile`:
   ```
   pod 'TMInstanceMethodSwizzler', :git => 'https://github.com/tuenti/TMInstanceMethodSwizzler'
   ```
2. Run `pod install`

### Manually

1. Clone, add as a submodule or [download TMInstanceMethodSwizzler](https://github.com/tuenti/TMInstanceMethodSwizzler/zipball/master).
2. Add all the files under `Classes` to your project.
3. Make sure your project is configured to use ARC.

## Credits & Contact

`TMInstanceMethodSwizzler` was created by [iOS team at Tuenti Technologies S.L.](http://github.com/tuenti).
You can follow Tuenti engineering team on Twitter [@tuentieng](http://twitter.com/tuentieng).

## License

`TMInstanceMethodSwizzler` is available under the Apache License, Version 2.0. See LICENSE file for more info.
