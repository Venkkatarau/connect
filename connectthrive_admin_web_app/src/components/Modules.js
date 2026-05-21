// src/components/Modules.js
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

const ModuleCard = styled(Card)(({ theme }) => ({
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

const Modules = () => {
  const [moduleName, setModuleName] = useState('');
  const [moduleDescription, setModuleDescription] = useState('');
  const [moduleType, setModuleType] = useState('free');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [modules, setModules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentModule, setCurrentModule] = useState(null);

  useEffect(() => {
    fetchModules();
  }, []);

  const fetchModules = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${process.env.REACT_APP_API_URL}/v2/admin/getAllModules`);
      setModules(response.data);
    } catch (error) {
      toast.error('Failed to fetch modules');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!moduleName.trim()) {
      toast.error('Module name cannot be empty');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = 
      { 
       name: moduleName,
       description : moduleDescription,
       tier: moduleType,
       course: {
               id: 1
               }
      };

      const response = editMode
        ? await axios.put(`${process.env.REACT_APP_API_URL}/v2/admin/updateModule/${currentModule.id}`, payload)
        : await axios.post(`${process.env.REACT_APP_API_URL}/v2/admin/addModule`, payload);

      toast.success(editMode ? 'Module updated' : 'Module added');
      fetchModules();
      setSubmitSuccess(true);
      setTimeout(() => {
        setOpenDialog(false);
        resetForm();
      }, 1500);
    } catch (error) {
      toast.error('Failed to submit module');
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setModuleName('');
    setModuleDescription('');
    setModuleType('free');
    setEditMode(false);
    setCurrentModule(null);
    setSubmitSuccess(false);
  };

  const handleEdit = (module) => {
    setCurrentModule(module);
    setModuleName(module.name);
    setModuleDescription(module.description);
    setModuleType(module.tier);
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
            Add/Edit Modules
          </Typography>
        </Box>

        <Box display="flex" justifyContent="flex-end" mb={4}>
          <StyledButton
            variant="contained"
            color="primary"
            startIcon={<Add />}
            onClick={() => setOpenDialog(true)}
          >
            Add New Module
          </StyledButton>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" py={6}>
            <CircularProgress size={60} color="primary" />
          </Box>
        ) : modules.length === 0 ? (
          <Box textAlign="center" py={8} border={1} borderColor="divider" borderRadius={12} sx={{ borderStyle: 'dashed' }}>
            <CollectionsBookmark sx={{ fontSize: 60, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" mb={2}>
              No modules found
            </Typography>
            <Typography variant="body1" color="text.secondary" mb={3}>
              Click "Add New Module" to create your first module
            </Typography>
            <StyledButton
              variant="outlined"
              color="primary"
              startIcon={<Add />}
              onClick={() => setOpenDialog(true)}
            >
              Add Module
            </StyledButton>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {modules.map((module) => (
              <Grid item xs={12} sm={6} md={4} key={module.id}>
                <ModuleCard variant="outlined">
                  <CardContent>
                    <Box display="flex" alignItems="center" gap={2} mb={1}>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <CollectionsBookmark />
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
                          {module.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {module.description}
                        </Typography>
                      </Box>
                      
                      <Tooltip title={`Tier: ${module.tier}`}>
                        <Chip
                          label={module.tier === 'free' ? 'Free' : 'Paid'}
                          color={module.tier === 'free' ? 'success' : 'primary'}
                          size="small"
                          sx={{ ml: 1 }}
                        />
                      </Tooltip>
                    </Box>
                  </CardContent>
                  <CardActions sx={{ justifyContent: 'flex-end', pr: 2, pb: 1 }}>
                    <Tooltip title="Edit">
                      <IconButton onClick={() => handleEdit(module)}>
                        <Edit color="primary" />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </ModuleCard>
              </Grid>
            ))}
          </Grid>
        )}

        <Dialog open={openDialog} onClose={handleDialogClose} maxWidth="sm" fullWidth>
          <DialogTitle>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Typography variant="h6">{editMode ? 'Edit Module' : 'Add New Module'}</Typography>
              <IconButton onClick={handleDialogClose}><Close /></IconButton>
            </Box>
          </DialogTitle>
          <DialogContent>
            <Box my={3}>
              <TextField
                fullWidth
                label="Module Name*"
                variant="outlined"
                value={moduleName}
                onChange={(e) => setModuleName(e.target.value)}
                placeholder="Enter module name"
                sx={{ borderRadius: 2, mb: 3 }}
              />
               <TextField
              label="Module Description"
              variant="outlined"
              fullWidth
              value={moduleDescription}
              onChange={(e) =>  setModuleDescription(e.target.value)}
              placeholder="Enter a module description"
              sx={{ borderRadius: 12 }}
             />
              <FormControl component="fieldset">
                <FormLabel component="legend">Module Type*</FormLabel>
                <RadioGroup
                  row
                  value={moduleType}
                  onChange={(e) => setModuleType(e.target.value)}
                >
                  <FormControlLabel value="free" control={<Radio />} label="Free" />
                  <FormControlLabel value="paid" control={<Radio />} label="Paid" />
                </RadioGroup>
              </FormControl>
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleDialogClose}>Cancel</Button>
            <StyledButton
              variant="contained"
              color="primary"
              endIcon={isSubmitting ? <CircularProgress size={24} color="inherit" /> : submitSuccess ? <CheckCircle /> : <Send />}
              onClick={handleSubmit}
              disabled={isSubmitting || !moduleName.trim()}
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

export default Modules;
