import Quickshell
import Quickshell.Io

import "modules/top"
import "modules/left"
import "modules/right"
import "modules/bottom"
import "modules/frame"
import "modules/lock"

ShellRoot {

    LeftBar {}

    RightBar {}

    BottomBar {}

    TopBar {}

    Lock {
        id: lockScreen
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.locked = true;
        }

        function unlock(): void {
            lockScreen.locked = false;
        }

        function toggle(): void {
            lockScreen.locked = !lockScreen.locked;
        }
    }

}
