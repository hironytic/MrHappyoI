<h3 align="center"><img src="Artwork/Logo.png" width="500" alt="Mr. Happyo I" /><br />Make a Presentation Performed by iOS</h3>

## Description

Mr. Happyo I, aka 発表くん１号, is an automated-presentation app for iOS. All speeches are produced by `AVSpeechSynthesizer` and all slides are shown in `PDFView`.

The idea was [submited](https://fortee.jp/iosdc-japan-2018/proposal/229db830-848e-4496-b863-46f8ba690c5d) to CfP for [iOSDC Japan 2018](https://iosdc.jp/2018/) by [Hiron](https://twitter.com/hironytic). At that time he thought it as a joke proposal, but then he had been interested in realizing the idea and started to work for this app. Few weeks later his proposal was selected and more seven weeks later he [made a presentation](https://youtu.be/bbKroWHw3dY?t=1m4s) about this app, with this app, without speaking any words!

## How to Use

This app is not submitted to AppStore. It is a kind of proof of concept. So you have to build it with your Xcode to use.

First of all, change bundle ID and code signing team to yours, then run.

You can get a PDF file from [Speaker Deck](https://speakerdeck.com/hironytic/iosdc-2018-lt) and a scenario JSON file from [this gist](https://gist.github.com/hironytic/aec041254892856f3a52fcd363dc41db). These are the files used for the presentation at iOSDC Japan 2018.

Steps to let iOS make a presentation:  
(The steps written in Japanese is [Here](https://qiita.com/hironytic/items/3476f0c50da5eae2ec7d#%E3%81%8A%E3%81%BE%E3%81%91))

1. Create a new document.

    <img width="50%" src="https://camo.qiitausercontent.com/cc1344f3643cd19e67245f95622791a78be0105a/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f33333339372f30323961353832662d336261332d626433642d643062342d3266353662313331333933652e706e67">

2. Tap "import" icon, then choose "スライドをインポート" (Import Slides) and specify a PDF file. Tap "import" icon again, choose "シナリオをインポート" (Import a Scenario) and then specify a scenario JSON file.

    <img width="50%" src="https://camo.qiitausercontent.com/ceae412d6fa7b4b7b61aae9a32b4b1c42cd95b5d/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f33333339372f35663564633533362d323532382d393934322d343466612d3539353166373935336339332e706e67">
    
    <img width="50%" src="https://camo.qiitausercontent.com/36cba41f8d443eedf212853419744e3145fd4862/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f33333339372f62653866383133322d383832622d653965662d353465662d3261633237366536356561332e706e67">

3. Tap "Play" icon. Touch the screen to start speaking.

    <img width="50%" src="https://camo.qiitausercontent.com/1c71afe4ed94aec249fc8d1bf3b6eddc5b664699/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f33333339372f63613033323635662d643135662d636263642d653663352d3935303135623464636230612e706e67">

4. Swipe from the bottom edge and tap "■" to end the presentation.

    <img width="50%" src="https://camo.qiitausercontent.com/888144db3e317033b9dd775817938af77a006a68/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f33333339372f38396364386632362d346436342d343536392d323439352d6138383031636162636137352e706e67">


## Author

Hironori Ichimiya, hiron@hironytic.com

## License

Mr. Happyo I, aka 発表くん１号, is available under the MIT license. See the LICENSE file for more info.

