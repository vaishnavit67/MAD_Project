const express = require('express');
const CampusLocation = require('../models/CampusLocation');
const defaultLocations = require('../data/campusLocations.json');

const router = express.Router();

/**
 * @route   GET /api/locations
 * @desc    Get all campus locations with optional category and search filters
 * @access  Public
 */
router.get('/', async (req, res) => {
  try {
    const { category, query } = req.query;
    let filter = {};

    if (category && category !== 'All') {
      filter.category = new RegExp(`^${category.trim()}$`, 'i');
    }

    if (query && query.trim()) {
      const regex = new RegExp(query.trim(), 'i');
      filter.$or = [
        { name: regex },
        { category: regex },
        { buildingCode: regex },
        { description: regex },
        { keywords: regex },
      ];
    }

    const locations = await CampusLocation.find(filter).sort({ name: 1 });

    return res.status(200).json({
      success: true,
      count: locations.length,
      locations: locations.map((loc) => loc.toJSON()),
    });
  } catch (error) {
    console.error('[Get Locations Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch campus locations',
    });
  }
});

/**
 * @route   GET /api/locations/:id
 * @desc    Get a single location by MongoDB ID or name
 * @access  Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    let location;

    if (id.match(/^[0-9a-fA-F]{24}$/)) {
      location = await CampusLocation.findById(id);
    } else {
      location = await CampusLocation.findOne({
        name: new RegExp(`^${id.trim()}$`, 'i'),
      });
    }

    if (!location) {
      return res.status(404).json({
        success: false,
        message: `Campus location '${id}' not found`,
      });
    }

    return res.status(200).json({
      success: true,
      location: location.toJSON(),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to retrieve location',
    });
  }
});

/**
 * @route   POST /api/locations
 * @desc    Add a new campus location
 * @access  Public
 */
router.post('/', async (req, res) => {
  try {
    const {
      name,
      category,
      description,
      distance,
      walkingTime,
      buildingCode,
      floorCount,
      isFavorite,
      keywords,
      checkpoints,
      latitude,
      longitude,
    } = req.body;

    if (!name || !category) {
      return res.status(400).json({
        success: false,
        message: 'Location name and category are required',
      });
    }

    const existing = await CampusLocation.findOne({
      name: new RegExp(`^${name.trim()}$`, 'i'),
    });

    if (existing) {
      return res.status(409).json({
        success: false,
        message: `A location with the name '${name}' already exists`,
      });
    }

    const newLoc = await CampusLocation.create({
      name: name.trim(),
      category: category.trim(),
      description: description || '',
      distance: distance || '850 m',
      walkingTime: walkingTime || '~10 min',
      buildingCode: buildingCode || '',
      floorCount: floorCount || 1,
      isFavorite: isFavorite || false,
      keywords: keywords || [],
      checkpoints: checkpoints || [],
      latitude: latitude != null ? Number(latitude) : null,
      longitude: longitude != null ? Number(longitude) : null,
    });

    return res.status(201).json({
      success: true,
      message: 'Campus location added successfully',
      location: newLoc.toJSON(),
    });
  } catch (error) {
    console.error('[Add Location Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to add campus location',
    });
  }
});

/**
 * @route   POST /api/locations/seed
 * @desc    Seed / sync the 53 campus locations from campusLocations.json into MongoDB
 * @access  Public / Admin
 */
router.post('/seed', async (req, res) => {
  try {
    let inserted = 0;
    let updated = 0;

    for (const locData of defaultLocations) {
      const payload = {
        name: locData.name,
        category: locData.category,
        description: locData.description || '',
        distance: locData.distance || '850 m',
        walkingTime: locData.walkingTime || '~10 min',
        buildingCode: locData.buildingCode || '',
        floorCount: locData.floorCount || 1,
        isFavorite: locData.isFavorite || false,
        keywords: locData.keywords || [],
        checkpoints: locData.checkpoints || [],
        latitude: locData.latitude,
        longitude: locData.longitude,
      };

      const existing = await CampusLocation.findOne({ name: locData.name });
      if (!existing) {
        await CampusLocation.create(payload);
        inserted++;
      } else {
        await CampusLocation.updateOne({ _id: existing._id }, payload);
        updated++;
      }
    }

    const totalCount = await CampusLocation.countDocuments();

    return res.status(200).json({
      success: true,
      message: `Locations synchronized successfully: ${inserted} inserted, ${updated} updated.`,
      totalInDatabase: totalCount,
    });
  } catch (error) {
    console.error('[Seed Locations Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to seed locations',
    });
  }
});

/**
 * @route   PUT /api/locations/:id
 * @desc    Update a campus location
 * @access  Public
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    delete updateData._id;
    delete updateData.id;

    const updated = await CampusLocation.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!updated) {
      return res.status(404).json({
        success: false,
        message: 'Campus location not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Campus location updated successfully',
      location: updated.toJSON(),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to update location',
    });
  }
});

/**
 * @route   DELETE /api/locations/:id
 * @desc    Delete a campus location
 * @access  Public
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await CampusLocation.findByIdAndDelete(id);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: 'Campus location not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: `Campus location '${deleted.name}' deleted successfully`,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete location',
    });
  }
});

module.exports = router;
