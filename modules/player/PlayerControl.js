// Handles executing standard media control parameters
function sendMediaCommand(executor, action) {
    executor.command = ["playerctl", "-p", "spotify", action];
    executor.start();
}