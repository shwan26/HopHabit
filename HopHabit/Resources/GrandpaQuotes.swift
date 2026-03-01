import Foundation

enum GrandpaQuotes {

    static let all: [String] = [
        "Every grain of rice begins with a single step, young one.",
        "The moon does not rush—it arrives exactly when it must.",
        "A rabbit who hops gently still moves forward.",
        "Discipline is not a cage. It is the sky you build for yourself.",
        "Ten thousand hours sounds heavy until you cook one bowl of rice at a time.",
        "Even on cloudy nights, the moon still shines above the clouds.",
        "The path is made by walking it, not by thinking about it.",
        "Small deeds done every day are worth more than great deeds planned for someday.",
        "The rabbit rests, yes—but the rabbit always hops again.",
        "Your future self is watching. Make them smile.",
        "A single flame is enough to light a room. Be the flame today.",
        "Do not count the steps remaining. Count the steps you have taken.",
        "The rice pot fills one grain at a time. So does a life well-lived.",
        "Patience is not waiting. It is doing, quietly.",
        "Tonight the moon is your witness. Go to sleep proud.",
    ]

    static func random() -> String {
        all.randomElement() ?? "Keep going—small steps count."
    }
}
