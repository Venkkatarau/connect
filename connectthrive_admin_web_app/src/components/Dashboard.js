import { useState } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Box,
  CssBaseline,
  Tooltip
} from '@mui/material';
import {
  Menu as MenuIcon,
  Logout,
  VideoLibrary,
  Class,
  School,
  MenuBook
} from '@mui/icons-material';
import { useNavigate, Routes, Route } from 'react-router-dom';

import UploadVideo from './UploadVideo';
import Batches from './Batches';
import BatchVideos from './BatchVideos';
import Modules from './Modules';
import Instance from './Instance';

const menuItems = [
    { text: 'BatchVideos', icon: <School />, path: 'batchVideos' },
  { text: 'Upload Video', icon: <VideoLibrary />, path: 'upload' },
  { text: 'Batches', icon: <Class />, path: 'batches' },
  { text: 'Modules', icon: <MenuBook />, path: 'modules' },
  //  { text: 'Instance', icon: <MenuBook />, path: 'instance' }
];

const Dashboard = () => {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const navigate = useNavigate();

  const handleLogout = () => {
    navigate('/');
  };

  return (
    <>
      <CssBaseline />

      {/* Navbar */}
      <AppBar position="static" sx={{ background: '#1a237e', boxShadow: 4 }}>
        <Toolbar sx={{ justifyContent: 'space-between' }}>
          <Box display="flex" alignItems="center">
            <IconButton
              edge="start"
              color="inherit"
              aria-label="menu"
              onClick={() => setDrawerOpen(true)}
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
            <Typography variant="h6" component="div" fontWeight="bold">
              🎓 Admin Dashboard
            </Typography>
          </Box>

          <Tooltip title="Logout">
            <IconButton color="inherit" onClick={handleLogout}>
              <Logout />
            </IconButton>
          </Tooltip>
        </Toolbar>
      </AppBar>

      {/* Drawer Sidebar */}
      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        PaperProps={{
          sx: {
            width: 250,
            backgroundColor: '#f5f5f5',
            borderTopRightRadius: '12px',
            borderBottomRightRadius: '12px',
          },
        }}
      >
        <Box role="presentation" sx={{ mt: 2 }}>
          <List>
            {menuItems.map((item) => (
              <ListItem
                button
                key={item.text}
                onClick={() => {
                navigate(`/dashboard/${item.path}`);
                setDrawerOpen(false);
                }}
                sx={{
                  '&:hover': {
                    backgroundColor: '#c5cae9',
                    transform: 'scale(1.02)',
                    transition: 'all 0.2s ease-in-out',
                  },
                }}
              >
                <ListItemIcon>{item.icon}</ListItemIcon>
                <ListItemText
                  primary={item.text}
                  primaryTypographyProps={{
                    fontWeight: 600,
                    color: '#1a237e',
                  }}
                />
              </ListItem>
            ))}
          </List>
        </Box>
      </Drawer>

      {/* Main Content */}
      <Box sx={{ padding: 4, minHeight: '90vh', backgroundColor: '#e8eaf6' }}>
        <Routes>
          <Route path="upload" element={<UploadVideo />} />
          <Route path="batches" element={<Batches />} />
          {/* <Route path="courses" element={<Courses />} /> */}
          <Route path="modules" element={<Modules />} />
          <Route path="batchVideos" element={<BatchVideos />} />
                <Route path="instance" element={<Instance />} />
        </Routes>
      </Box>
    </>
  );
};

export default Dashboard;
