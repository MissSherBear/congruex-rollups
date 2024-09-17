trigger UpdateIsActive on Account (before insert, before update) {
    new updateIsActiveHandler().run();
}