<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.Login" Async="true" UnobtrusiveValidationMode="None" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Login - Face Recognition System</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #e058d9 0%, #f28eea 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-container {
            background-color: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            max-width: 450px;
            width: 100%;
        }
        .login-header {
            text-align: center;
            margin-bottom: 30px;
        }
        .login-header h2 {
            color: #333;
            margin: 0;
            font-size: 28px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #333;
        }
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 14px;
            box-sizing: border-box;
            transition: border-color 0.3s;
        }
        .form-group input:focus {
            border-color: #007bff;
            outline: none;
            box-shadow: 0 0 5px rgba(0,123,255,0.3);
        }
        .btn {
            width: 100%;
            background-color: #007bff;
            color: white;
            padding: 14px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
            transition: background-color 0.3s;
            margin-bottom: 15px;
        }
        .btn:hover {
            background-color: #0056b3;
        }
        .btn-secondary {
            background-color: #6c757d;
        }
        .btn-secondary:hover {
            background-color: #545b62;
        }
        .short-pass-input {
            text-align: center;
            font-size: 24px;
            font-weight: bold;
            letter-spacing: 8px;
        }
        .message {
            padding: 12px;
            margin: 15px 0;
            border-radius: 8px;
            text-align: center;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .register-link {
            text-align: center;
            margin-top: 25px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        .register-link a {
            color: #007bff;
            text-decoration: none;
            font-weight: bold;
        }
        .register-link a:hover {
            text-decoration: underline;
        }
        /* Hidden sections */
        .login-methods {
            display: none !important;
        }
        .face-recognition-section {
            display: none !important;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }
        .modal-content {
            background-color: white;
            margin: 15% auto;
            padding: 30px;
            border-radius: 15px;
            width: 90%;
            max-width: 400px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            animation: slideIn 0.3s;
        }
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        @keyframes slideIn {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        .modal-header {
            margin-bottom: 20px;
        }
        .modal-header h3 {
            color: #333;
            margin: 0;
            font-size: 24px;
        }
        .user-info {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .user-info h4 {
            margin: 0 0 5px 0;
            color: #007bff;
        }
        .user-info p {
            margin: 0;
            color: #666;
            font-size: 14px;
        }
        .close-modal {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
        }
        .close-modal:hover {
            color: #000;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="login-container">
            <div class="login-header">
                <h2>Face Scan para makita mo halaga ko</h2>
                <p style="color: #666; margin: 10px 0 0 0;">Enter your credentials to continue</p>
            </div>

            <!-- Success/Error Messages -->
            <asp:Panel ID="pnlMessage" runat="server" Visible="false">
                <asp:Label ID="lblMessage" runat="server" />
            </asp:Panel>

            <!-- Face Recognition Section (Hidden but functional) -->
            <div class="face-recognition-section">
                <video id="loginVideo" autoplay muted style="display: none;"></video>
                <canvas id="loginCanvas" style="display: none;"></canvas>
                <asp:HiddenField ID="hfFaceLoginEncoding" runat="server" />
                <asp:HiddenField ID="hfRecognizedUserId" runat="server" />
                <asp:Button ID="btnFaceLogin" runat="server" Text="Process Face Recognition" 
                    OnClick="btnFaceLogin_Click" style="display: none;" />
            </div>

            <!-- Email/Password Login -->
            <div class="form-group">
                <label for="txtEmail">Email Address:</label>
                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" 
                    placeholder="Enter your email address" />
            </div>

            <div class="form-group">
                <label for="txtPassword">Password:</label>
                <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" 
                    placeholder="Enter your password" />
            </div>

            <asp:Button ID="btnEmailLogin" runat="server" CssClass="btn" Text="Login" 
                OnClick="btnEmailLogin_Click" />

            <!-- Register Link -->
            <div class="register-link">
                <p>Don't have an account? <a href="Register.aspx">Register here</a></p>
            </div>
        </div>

        <!-- Short Pass Modal -->
        <div id="shortPassModal" class="modal">
            <div class="modal-content">
                <span class="close-modal" onclick="closeShortPassModal()">&times;</span>
                <div class="modal-header">
                    <h3>✅ Face Recognized!</h3>
                </div>
                <div class="user-info">
                    <h4 id="recognizedUserName">Welcome back!</h4>
                    <p id="recognizedUserEmail"></p>
                </div>
                <div class="form-group">
                    <label for="txtModalShortPass">Enter your 4-digit PIN to continue:</label>
                    <asp:TextBox ID="txtModalShortPass" runat="server" CssClass="form-control short-pass-input" 
                        MaxLength="4" placeholder="0000" />
                </div>
                <asp:Button ID="btnModalShortPassLogin" runat="server" CssClass="btn" Text="Complete Login" 
                    OnClick="btnModalShortPassLogin_Click" />
                <button type="button" class="btn btn-secondary" onclick="closeShortPassModal()">Cancel</button>
            </div>
        </div>

        <!-- Hidden fields for backward compatibility -->
        <asp:TextBox ID="txtEmailShort" runat="server" style="display: none;" />
        <asp:TextBox ID="txtShortPassLogin" runat="server" style="display: none;" />
        <asp:Button ID="btnShortPassLogin" runat="server" style="display: none;" OnClick="btnShortPassLogin_Click" />
    </form>

    <script>
        let loginVideo = document.getElementById('loginVideo');
        let loginCanvas = document.getElementById('loginCanvas');
        let loginContext = loginCanvas.getContext('2d');
        let loginStream = null;
        let faceRecognitionInterval = null;
        let isProcessingFace = false;
        let loginSuccessful = false; // Add flag to track successful login

        // Global functions for face recognition
        window.showShortPassModal = function(userName, userEmail, userId) {
            document.getElementById('recognizedUserName').textContent = userName;
            document.getElementById('recognizedUserEmail').textContent = userEmail;
            document.getElementById('<%= hfRecognizedUserId.ClientID %>').value = userId;
            document.getElementById('shortPassModal').style.display = 'block';
            document.getElementById('<%= txtModalShortPass.ClientID %>').focus();
            stopFaceRecognition();
        };

        window.closeShortPassModal = function() {
            if (!loginSuccessful) { // Only restart if login wasn't successful
                document.getElementById('shortPassModal').style.display = 'none';
                document.getElementById('<%= txtModalShortPass.ClientID %>').value = '';
                document.getElementById('<%= hfRecognizedUserId.ClientID %>').value = '';
                setTimeout(startFaceRecognition, 500);
            }
        };

        window.faceRecognitionFailed = function() {
            if (!loginSuccessful) {
                isProcessingFace = false;
            }
        };

        // Function to mark login as successful and stop all face recognition
        window.markLoginSuccessful = function() {
            console.log('Login marked as successful!'); // Debug log
            loginSuccessful = true;
            stopFaceRecognition();
            document.getElementById('shortPassModal').style.display = 'none';
        };

        // Auto-start face recognition when page loads
        window.addEventListener('load', function() {
            if (!loginSuccessful) {
                setTimeout(startFaceRecognition, 1000);
            }
        });

        async function startFaceRecognition() {
            if (loginSuccessful) return; // Don't start if login was successful
            
            try {
                loginStream = await navigator.mediaDevices.getUserMedia({ video: true });
                loginVideo.srcObject = loginStream;
                faceRecognitionInterval = setInterval(captureAndRecognizeFace, 5000);
                console.log('Face recognition started'); // Debug log
            } catch (err) {
                console.log('Face recognition not available:', err); // Debug log
            }
        }

        function stopFaceRecognition() {
            console.log('Stopping face recognition'); // Debug log
            if (loginStream) {
                loginStream.getTracks().forEach(track => track.stop());
                loginStream = null;
            }
            if (faceRecognitionInterval) {
                clearInterval(faceRecognitionInterval);
                faceRecognitionInterval = null;
            }
            isProcessingFace = false;
        }

        function captureAndRecognizeFace() {
            if (!loginStream || !loginVideo.videoWidth || isProcessingFace || loginSuccessful) return;

            isProcessingFace = true;
            loginCanvas.width = loginVideo.videoWidth;
            loginCanvas.height = loginVideo.videoHeight;
            loginContext.drawImage(loginVideo, 0, 0);

            const imageData = loginCanvas.toDataURL('image/jpeg', 0.8);
            const faceEncoding = btoa(imageData);

            document.getElementById('<%= hfFaceLoginEncoding.ClientID %>').value = faceEncoding;
            document.getElementById('<%= btnFaceLogin.ClientID %>').click();
        }

        // Short pass input formatting
        document.addEventListener('DOMContentLoaded', function() {
            const shortPassInput = document.getElementById('<%= txtModalShortPass.ClientID %>');
            if (shortPassInput) {
                shortPassInput.addEventListener('input', function(e) {
                    this.value = this.value.replace(/[^0-9]/g, '').substring(0, 4);
                    if (this.value.length === 4) {
                        setTimeout(() => {
                            document.getElementById('<%= btnModalShortPassLogin.ClientID %>').click();
                        }, 500);
                    }
                });
            }

            // Initial focus on email
            const emailInput = document.getElementById('<%= txtEmail.ClientID %>');
            if (emailInput) {
                emailInput.focus();
            }
        });

        // Enter key handling
        document.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                const modal = document.getElementById('shortPassModal');
                if (modal && modal.style.display === 'block') {
                    document.getElementById('<%= btnModalShortPassLogin.ClientID %>').click();
                } else {
                    document.getElementById('<%= btnEmailLogin.ClientID %>').click();
                }
            }
        });

        // Cleanup on page unload
        window.addEventListener('beforeunload', function() {
            stopFaceRecognition();
        });

        // Close modal when clicking outside
        window.addEventListener('click', function(event) {
            const modal = document.getElementById('shortPassModal');
            if (event.target === modal && !loginSuccessful) {
                window.closeShortPassModal();
            }
        });

        // Close modal function for onclick events
        function closeShortPassModal() {
            window.closeShortPassModal();
        }

        // Alternative redirect function in case the above doesn't work
        window.redirectToDashboard = function() {
            console.log('Attempting to redirect to dashboard');
            window.location.replace('../Admin/Dashboard.aspx');
        };
    </script>
</body>
</html>
