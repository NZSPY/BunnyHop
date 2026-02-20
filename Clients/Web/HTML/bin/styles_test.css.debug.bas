/* styles.css */
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            background-color: #f0f8ff;
        }

        h1 {
            color: #333;
        }

        .game-table-list {
            width: 90%;
            max-width: 600px;
            margin: 20px auto;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 8px;
            background: #fff;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .game-table-item {
            padding: 10px;
            border-bottom: 1px solid #eee;
        }

        .game-table-item:last-child {
            border-bottom: none;
        }

        .game-table-name {
            font-weight: bold;
        }

        .game-table-status {
            color: #666;
        }
    
GET ___DEBUG_KEY