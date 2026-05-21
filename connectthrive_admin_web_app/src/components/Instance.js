// src/components/instance.js
import { useState, useEffect } from 'react';
import {
  Box, Typography, Paper, TextField, Button, CircularProgress, Dialog, DialogTitle,
  DialogContent, DialogActions, IconButton, Avatar, Grid, Card, CardContent, CardActions,
  Chip, Container, Tooltip, Radio, RadioGroup, FormControlLabel,
  FormControl, FormLabel
} from '@mui/material';
import {
  Add, CheckCircle, Close, Edit, CollectionsBookmark, Send
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import VerifiedIcon from '@mui/icons-material/Verified';
import axios from 'axios';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const StyledPaper = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(4),
  borderRadius: 16,
  background: 'linear-gradient(to bottom right, #f5f7fa, #e4e8f0)',
  boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
}));

const StyledButton = styled(Button)(({ theme }) => ({
  borderRadius: 12,
  padding: '10px 24px',
  fontWeight: 600,
  textTransform: 'none',
  letterSpacing: 0.5,
  transition: 'all 0.3s ease',
  '&:hover': {
    transform: 'translateY(-2px)',
    boxShadow: theme.shadows[4],
  },
}));

const InstanceCard = styled(Card)(({ theme }) => ({
  borderRadius: 12,
  transition: 'all 0.3s ease',
  width: 346,
  margin: '0 auto',
  '&:hover': {
    transform: 'translateY(-4px)',
    boxShadow: theme.shadows[6],
    borderColor: theme.palette.primary.main,
  },
}));

const Instance = () => {
  const [link, setLink] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [instance, setInstance] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentInstance, setCurrentInstance] = useState(null);

  useEffect(() => {
    fetchInstance();
  }, []);

  const fetchInstance = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${process.env.REACT_APP_API_URL}/v2/admin/getAllInstances`);
      setInstance(response.data);
    } catch (error) {
      toast.error('Failed to fetch Instance');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!link.trim()) {
      toast.error('Instance link cannot be empty');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = 
      { 
       username: username,
       password : password,
       link: link 
      };

      const response = editMode
        ? await axios.put(`${process.env.REACT_APP_API_URL}/v2/admin/instance/${currentInstance.id}`, payload)
        : await axios.post(`${process.env.REACT_APP_API_URL}/v2/admin/addInstance`, payload);

      toast.success(editMode ? 'Instance updated' : 'Instance added');
      fetchInstance();
      setSubmitSuccess(true);
      setTimeout(() => {
        setOpenDialog(false);
        resetForm();
      }, 1500);
    } catch (error) {
      toast.error('Failed to submit instance');
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setLink('');
    setUsername('');
    setPassword('');
    setEditMode(false);
    setCurrentInstance(null);
    setSubmitSuccess(false);
  };

  const handleEdit = (instance) => {
    setCurrentInstance(instance);
    setLink(instance.link);
    setUsername(instance.username);
    setPassword(instance.password);
    setEditMode(true);
    setOpenDialog(true);
  };

  const handleDialogClose = () => {
    setOpenDialog(false);
    resetForm();
  };

  return (
    <Container maxWidth="lg">
      <StyledPaper>
        <Box display="flex" alignItems="center" gap={2} mb={3}>
          <CollectionsBookmark sx={{ fontSize: 40, color: '#3f51b5' }} />
          <Typography variant="h4" fontWeight="bold" color="#1a237e">
            Add/Edit Instance
          </Typography>
        </Box>

        <Box display="flex" justifyContent="flex-end" mb={4}>
          <StyledButton
            variant="contained"
            color="primary"
            startIcon={<Add />}
            onClick={() => setOpenDialog(true)}
          >
            Add New Instance
          </StyledButton>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" py={6}>
            <CircularProgress size={60} color="primary" />
          </Box>
        ) : instance.length === 0 ? (
          <Box textAlign="center" py={8} border={1} borderColor="divider" borderRadius={12} sx={{ borderStyle: 'dashed' }}>
            <CollectionsBookmark sx={{ fontSize: 60, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" mb={2}>
              No Instance found
            </Typography>
            <Typography variant="body1" color="text.secondary" mb={3}>
              Click "Add New Instance" to create your first Instance
            </Typography>
            <StyledButton
              variant="outlined"
              color="primary"
              startIcon={<Add />}
              onClick={() => setOpenDialog(true)}
            >
              Add Instance
            </StyledButton>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {instance.map((instance) => (
              <Grid item xs={12} sm={6} md={4} key={instance.id}>
                <InstanceCard variant="outlined">
                  <CardContent>
                    <Box display="flex" alignItems="center" gap={2} mb={1}>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <VerifiedIcon  />
                      </Avatar>
                      <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography
                          variant="h6"
                          sx={{
                            overflow: 'hidden',
                            whiteSpace: 'nowrap',
                            textOverflow: 'ellipsis',
                            fontWeight: 600,
                          }}
                        >
                          {instance.username}
                        </Typography>
                        {/* <Typography variant="caption" color="text.secondary">
                          {instance.password}
                        </Typography> */}
                      </Box>
                    </Box>
                  </CardContent>
                  <CardActions sx={{ justifyContent: 'flex-end', pr: 2, pb: 1 }}>
                    <Tooltip title="Edit">
                      <IconButton onClick={() => handleEdit(instance)}>
                        <Edit color="primary" />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </InstanceCard>
              </Grid>
            ))}
          </Grid>
        )}

        <Dialog open={openDialog} onClose={handleDialogClose} maxWidth="sm" fullWidth>
          <DialogTitle>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Typography variant="h6">{editMode ? 'Edit Instance' : 'Add New Instance'}</Typography>
              <IconButton onClick={handleDialogClose}><Close /></IconButton>
            </Box>
          </DialogTitle>
          <DialogContent>
            <Box my={3}>
              <TextField
                fullWidth
                label="Instance Link*"
                variant="outlined"
                value={link}
                onChange={(e) => setLink(e.target.value)}
                placeholder="Enter Instance Link"
                sx={{ borderRadius: 2, mb: 3 }}
              />
               <TextField
              label="Instance username"
              variant="outlined"
              fullWidth
              value={username}
              onChange={(e) =>  setUsername(e.target.value)}
              placeholder="Enter Username"
              sx={{ borderRadius: 12 }}
             />
              <TextField
              label="Instance password"
              variant="outlined"
              fullWidth
              value={password}
              onChange={(e) =>  setPassword(e.target.value)}
              placeholder="Enter password"
              sx={{ borderRadius: 12 }}
             />
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleDialogClose}>Cancel</Button>
            <StyledButton
              variant="contained"
              color="primary"
              endIcon={isSubmitting ? <CircularProgress size={24} color="inherit" /> : submitSuccess ? <CheckCircle /> : <Send />}
              onClick={handleSubmit}
              disabled={isSubmitting || !link.trim() || !username.trim() || !password.trim()}
              sx={{
                minWidth: 120,
                ...(submitSuccess && {
                  backgroundColor: '#4caf50',
                  '&:hover': { backgroundColor: '#388e3c' }
                }),
              }}
            >
              {isSubmitting ? 'Saving...' : submitSuccess ? 'Saved!' : 'Save'}
            </StyledButton>
          </DialogActions>
        </Dialog>
      </StyledPaper>
       <ToastContainer position="top-right" autoClose={3000} hideProgressBar />
    </Container>
  );
};

export default Instance;
