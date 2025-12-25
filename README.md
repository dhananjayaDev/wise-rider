![Ride Wise Banner](banner.jpeg)

# Ride Wise 🏍️💨

**Ride Wise** is a smart motorcycle trip planner designed to help riders navigate safer and smarter. Unlike standard navigation apps, Ride Wise focuses on the *quality* of the ride, providing route-specific weather forecasts and AI-powered safety advice.

## 🚀 Features

*   **Multi-Stop Routing**: Plan complex trips with unlimited waypoints using OSRM.
*   **Dynamic Weather Agility**: Get "City-by-City" hourly weather forecasts for every stop on your route using Open-Meteo.
*   **AI Copilot**: Powered by **Groq (Mixtral-8x7b)**, our local AI agent analyzes weather patterns along your route to provide precise, location-specific safety warnings (e.g., "Heavy rain expected at Bentota, slow down").
*   **Visual Map Interface**: Interactive map with distinct markers for Start (Green), Stops (Cyan), and Destination (Orange).
*   **Premium Dark UI**: A sleek, rider-focused dark mode interface using Material 3 design principles.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart) - Optimized for Web, Mobile, and Desktop.
*   **Routing API**: OSRM (Open Source Routing Machine).
*   **Weather API**: Open-Meteo (Free, non-commercial use).
*   **AI Logic**: Groq API (Running Mixtral-8x7b).
*   **State Management**: Flutter Riverpod.
*   **Maps**: `flutter_map` with OpenStreetMap tiles.

## 📸 Screenshots

*(Add your screenshots here)*

## 📦 Getting Started

### Prerequisites
*   Flutter SDK installed.
*   A free API Key from [Groq](https://groq.com/).

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/dhananjayaDev/wise-rider.git
    cd wise-rider
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Setup Environment**:
    Create a `.env` file in the root directory and add your keys:
    ```env
    GROQ_API_KEY=your_api_key_here
    OSRM_API_URL=http://router.project-osrm.org/route/v1/driving
    ```

4.  **Run the App**:
    ```bash
    flutter run
    ```

## 🌐 Live Demo

Check out the live web version here: [https://wise-rider.web.app](https://wise-rider.web.app)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.
