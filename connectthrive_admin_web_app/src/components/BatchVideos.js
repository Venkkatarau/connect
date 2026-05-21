import React, { useState, useEffect } from 'react';
import {
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Box,
  Typography,
  CircularProgress,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Checkbox,
  FormGroup,
  FormControlLabel,
  Divider,
  Paper,
  Chip
} from '@mui/material';

import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import EditIcon from '@mui/icons-material/Edit';
import DownloadIcon from '@mui/icons-material/Download';
import DescriptionIcon from '@mui/icons-material/Description';
import axios from 'axios';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const API_URL = `${process.env.REACT_APP_API_URL}/v2/conceptsGroupByModule`;
const BATCHES_URL = `${process.env.REACT_APP_API_URL}/v1/admin/getAllBatches`;
const SYNC_URL = `${process.env.REACT_APP_API_URL}/v1/admin/syncBatchConcepts`;
const THUMBNAIL_BASE_URL = 'https://dbp6bbvk4lzrp.cloudfront.net/';

const BatchVideos = () => {
  const [modules, setModules] = useState([]);
  const [batches, setBatches] = useState([]);
  const [expanded, setExpanded] = useState(false);
  const [loading, setLoading] = useState(true);

  const [batchDialog, setBatchDialog] = useState({ open: false, concept: null });
  const [batchSelection, setBatchSelection] = useState({});

  useEffect(() => {
    Promise.all([axios.get(API_URL), axios.get(BATCHES_URL)])
      .then(([conceptRes, batchRes]) => {
        setModules(conceptRes.data);
        setBatches(batchRes.data);
      })
      .catch(err => console.error('Error fetching data:', err))
      .finally(() => setLoading(false));
  }, []);

  const handleExpand = (id) => (_, isExpanded) => {
    setExpanded(isExpanded ? id : false);
  };

  const openBatchDialog = (concept) => {
    const selected = {};
    batches.forEach(batch => {
      selected[batch.name] = concept.batchList.some(c => c.name === batch.name);
    });
    setBatchSelection(selected);
    setBatchDialog({ open: true, concept });
  };

  const handleCheckboxChange = (batchName) => {
    setBatchSelection(prev => ({ ...prev, [batchName]: !prev[batchName] }));
  };

  const handleSubmitBatch = () => {
    const selectedBatchIds = batches
      .filter(batch => batchSelection[batch.name])
      .map(batch => batch.id);

    const conceptId = batchDialog.concept.id;

    const payload = {
      batchId: selectedBatchIds,
      conceptIds: conceptId,
    };

    axios
      .post(SYNC_URL, payload, { headers: { 'Content-Type': 'application/json' } })
      .then(() => {
        toast.success('Batch-Concepts synced successfully');
        return axios.get(API_URL);
      })
      .then((res) => {
        setModules(res.data);
        setBatchDialog({ open: false, concept: null });
      })
      .catch((err) => {
        console.error('Sync failed:', err);
        toast.error('Failed to sync batch-concepts');
      });
  };

  const handleDownload = (videoUrl, title) => {
    if (!videoUrl) {
      toast.error('Video URL is missing');
      return;
    }
    const fullUrl = 'https://dbp6bbvk4lzrp.cloudfront.net/' + videoUrl;
    const link = document.createElement('a');
    link.href = fullUrl;
    link.setAttribute('download', `${title}.mp4`);
    link.setAttribute('target', '_blank');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const renderConceptBox = (concept) => (
    <Box
      key={concept.id}
      sx={{
        display: 'flex',
        alignItems: 'center',
        mb: 1.5,
        gap: 2,
        p: 1.5,
        borderRadius: '8px',
        background: '#f8f9fa',
        border: '1px solid #f1f3f5',
        '&:hover': {
          background: '#f1f3f5',
          transform: 'translateY(-2px)'
        },
        transition: 'all 0.2s ease'
      }}
    >
      <img
        src={THUMBNAIL_BASE_URL + concept.thumbnailFileName}
        alt={concept.title}
        style={{
          width: 90,
          height: 55,
          borderRadius: 6,
          objectFit: 'cover',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}
      />
      <Box sx={{ flexGrow: 1 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600, color: '#2c3e50' }}>{concept.title}</Typography>
        <Typography variant="caption" color="text.secondary">
          Assigned Batches: {concept.batchList.map((b) => b.name).join(', ')}
        </Typography>
        {concept.supportingDocuments && concept.supportingDocuments.length > 0 && (
          <Box sx={{ mt: 1, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
            {concept.supportingDocuments.map((doc, idx) => {
              const displayName = doc.split('_').slice(1).join('_') || `Document ${idx + 1}`;
              return (
                <Button
                  key={idx}
                  size="small"
                  variant="outlined"
                  startIcon={<DescriptionIcon />}
                  onClick={() => handleDownload(doc, displayName)}
                  sx={{ textTransform: 'none', py: 0.1, px: 1, fontSize: '0.72rem', color: '#1a237e', borderColor: '#1a237e' }}
                >
                  {displayName}
                </Button>
              );
            })}
          </Box>
        )}
      </Box>
      <IconButton
        onClick={() => handleDownload(concept.videoUrl, concept.title)}
        sx={{ color: '#1a237e', mr: 1 }}
        title="Download Video"
      >
        <DownloadIcon />
      </IconButton>
      <IconButton onClick={() => openBatchDialog(concept)}>
        <EditIcon sx={{ color: '#546e7a' }} />
      </IconButton>
    </Box>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={6}>
        <CircularProgress size={60} color="primary" />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      {batches.map((batch) => {
        // Filter modules and concepts belonging to this batch
        const batchModules = modules.map(module => {
          const concepts = (module.concepts || []).filter(c => 
            c.batchList.some(b => b.id === batch.id)
          );
          const transactionConcepts = (module.transactionConcepts || []).filter(c => 
            c.batchList.some(b => b.id === batch.id)
          );
          return {
            ...module,
            concepts,
            transactionConcepts
          };
        }).filter(m => m.concepts.length > 0 || m.transactionConcepts.length > 0);

        const totalVideos = batchModules.reduce((acc, m) => acc + m.concepts.length + m.transactionConcepts.length, 0);

        return (
          <Accordion
            key={batch.id}
            expanded={expanded === batch.id}
            onChange={handleExpand(batch.id)}
            sx={{
              mb: 2,
              borderRadius: '12px !important',
              boxShadow: '0 4px 20px 0 rgba(0,0,0,0.05)',
              border: '1px solid #e0e0e0',
              overflow: 'hidden',
              '&:before': { display: 'none' },
              '&:hover': {
                borderColor: '#1a237e',
                boxShadow: '0 6px 24px 0 rgba(26, 35, 126, 0.08)'
              },
              transition: 'all 0.3s ease'
            }}
          >
            <AccordionSummary 
              expandIcon={<ExpandMoreIcon sx={{ color: '#1a237e' }} />}
              sx={{
                background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
                px: 3,
                py: 1
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', width: '100%', justifyContent: 'space-between', pr: 2 }}>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: '#1a237e' }}>
                    {batch.name}
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                    Batch ID: {batch.id}
                  </Typography>
                </Box>
                <Chip 
                  label={`${totalVideos} Videos`} 
                  color="primary" 
                  size="small" 
                  sx={{ 
                    fontWeight: 600, 
                    background: '#1a237e',
                    px: 1 
                  }} 
                />
              </Box>
            </AccordionSummary>
            
            <AccordionDetails sx={{ p: 3, background: '#fafafa' }}>
              {batchModules.length === 0 ? (
                <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 3 }}>
                  No videos assigned to this batch.
                </Typography>
              ) : (
                batchModules.map((module) => (
                  <Paper
                    key={module.id}
                    elevation={0}
                    sx={{
                      p: 2.5,
                      mb: 2.5,
                      borderRadius: '10px',
                      border: '1px solid #eaeaea',
                      background: '#fff'
                    }}
                  >
                    <Typography 
                      variant="subtitle1" 
                      sx={{ 
                        fontWeight: 700, 
                        color: '#2c3e50', 
                        mb: 1.5,
                        display: 'flex',
                        alignItems: 'center',
                        gap: 1
                      }}
                    >
                      {module.name}
                      <Chip 
                        label={module.tier} 
                        size="small" 
                        variant="outlined"
                        color={module.tier === 'FREE' ? 'success' : 'warning'}
                        sx={{ fontSize: '0.7rem', height: 20 }}
                      />
                    </Typography>
                    
                    {module.concepts && module.concepts.length > 0 && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600, color: '#7f8c8d' }}>
                          SetUp:——&gt;
                        </Typography>
                        {module.concepts.map(renderConceptBox)}
                      </Box>
                    )}

                    {module.transactionConcepts && module.transactionConcepts.length > 0 && (
                      <Box>
                        {module.concepts && module.concepts.length > 0 && <Divider sx={{ my: 1.5 }} />}
                        <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600, color: '#7f8c8d' }}>
                          Transaction:—&gt;
                        </Typography>
                        {module.transactionConcepts.map(renderConceptBox)}
                      </Box>
                    )}
                  </Paper>
                ))
              )}
            </AccordionDetails>
          </Accordion>
        );
      })}

      {/* Dynamic Batch Dialog */}
      <Dialog
        open={batchDialog.open}
        onClose={() => setBatchDialog({ open: false, concept: null })}
      >
        <DialogTitle>Select Batches</DialogTitle>
        <DialogContent>
          <FormGroup>
            {batches.map((batch) => (
              <FormControlLabel
                key={batch.id}
                control={
                  <Checkbox
                    checked={batchSelection[batch.name] || false}
                    onChange={() => handleCheckboxChange(batch.name)}
                  />
                }
                label={batch.name}
              />
            ))}
          </FormGroup>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSubmitBatch} variant="contained">
            Submit
          </Button>
        </DialogActions>
      </Dialog>

      <ToastContainer position="top-right" autoClose={3000} hideProgressBar />
    </Box>
  );
};

export default BatchVideos;

