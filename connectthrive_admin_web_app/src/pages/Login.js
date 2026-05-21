import { useState } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Grid,
  Box,
  Paper,
  TextField,
  Button,
  IconButton,
  InputAdornment,
  CssBaseline,
  CircularProgress
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Person,
  Lock
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const Login = () => {
  const navigate = useNavigate();
  const [values, setValues] = useState({ username: '', password: '', showPassword: false });
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    setLoading(true);
    try {
      const res = await axios.post(`${process.env.REACT_APP_API_URL}/v1/admin/login`, {
        username: values.username,
        password: values.password,
      },
      {
         headers: {
         'Content-Type': 'application/json',
         'Accept': 'application/json'
      }
  });

      if (res.status === 200 && (res.data.status || res.data.success)) {
        toast.success(res.data.message || "Login successful!", { position: "top-right" });
        setTimeout(() => {
          navigate('/dashboard');
        }, 1500);
      }
    } catch (err) {
      if (err.response && err.response.data) {
        toast.error(err.response.data.message, { position: "top-right" });
      } else {
        toast.error("Something went wrong. Please try again.", { position: "top-right" });
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <CssBaseline />
      <ToastContainer />

      {/* Navbar*/}
      <AppBar
        position="static"
        elevation={3}
        sx={{ backgroundColor: '#1a237e' }}
      >
        <Toolbar>
          <Typography variant="h6" fontWeight="bold">
            🛠️ Admin Control Panel
          </Typography>
        </Toolbar>
      </AppBar>

      {/* Centered Login Form */}
      <Grid
        container
        justifyContent="center"
        alignItems="center"
        sx={{ height: '90vh', backgroundColor: '#e8eaf6' }}
      >
        <Grid item xs={11} sm={8} md={5} lg={4}>
          <Paper elevation={10} sx={{ p: 5, borderRadius: 4 }}>
            <Box textAlign="center" mb={3}>
              <Lock sx={{ fontSize: 50, color: '#1a237e' }} />
              <Typography variant="h5" fontWeight="bold" mt={1}>
                Admin Login
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Enter your credentials to access the dashboard
              </Typography>
            </Box>

            <TextField
              fullWidth
              label="Username"
              margin="normal"
              variant="outlined"
              value={values.username}
              onChange={(e) => setValues({ ...values, username: e.target.value })}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Person />
                  </InputAdornment>
                ),
              }}
            />

            <TextField
              fullWidth
              label="Password"
              margin="normal"
              variant="outlined"
              type={values.showPassword ? 'text' : 'password'}
              value={values.password}
              onChange={(e) => setValues({ ...values, password: e.target.value })}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Lock />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() =>
                        setValues((prev) => ({ ...prev, showPassword: !prev.showPassword }))
                      }
                      edge="end"
                    >
                      {values.showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <Button
              fullWidth
              variant="contained"
              size="large"
              disabled={loading}
              sx={{
                mt: 3,
                py: 1.2,
                fontWeight: 'bold',
                backgroundColor: '#1a237e',
                '&:hover': {
                  backgroundColor: '#303f9f'
                },
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
              onClick={handleLogin}
            >
              {loading ? (
                <CircularProgress size={24} sx={{ color: 'white' }} />
              ) : (
                'Sign In'
              )}
            </Button>
          </Paper>
        </Grid>
      </Grid>
    </>
  );
};

export default Login;
